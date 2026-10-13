using System.Collections.Concurrent;
using System.Net.Http.Headers;
using System.Security.Claims;
using System.Text.Json;
using FinTrack.Application.Common;
using FinTrack.Application.Interfaces;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Protocols;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;

namespace FinTrack.Infrastructure.Auth.Sso;

public class OidcIdentityProviderClient : IIdentityProviderClient
{
    private const string HttpClientName = "fintrack-sso";
    private const string MicrosoftAccountTenant = "9188040d-6c67-4c5b-b112-36a304b66dad";
    private static readonly string[] AllowedAlgorithms =
    [
        SecurityAlgorithms.RsaSha256,
        SecurityAlgorithms.RsaSha384,
        SecurityAlgorithms.RsaSha512,
        SecurityAlgorithms.EcdsaSha256,
        SecurityAlgorithms.EcdsaSha384,
        SecurityAlgorithms.EcdsaSha512
    ];

    private readonly IOptions<SsoOptions> _options;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IHostEnvironment _environment;
    private readonly ILogger<OidcIdentityProviderClient> _logger;
    private readonly ConcurrentDictionary<string, ConfigurationManager<OpenIdConnectConfiguration>> _metadata = new();

    public OidcIdentityProviderClient(
        IOptions<SsoOptions> options,
        IHttpClientFactory httpClientFactory,
        IHostEnvironment environment,
        ILogger<OidcIdentityProviderClient> logger)
    {
        _options = options;
        _httpClientFactory = httpClientFactory;
        _environment = environment;
        _logger = logger;
        foreach (var provider in Describe())
        {
            if (provider.Enabled && !provider.IsReady)
            {
                _logger.LogWarning("SSO provider {Provider} is enabled but incomplete, so it stays hidden", provider.Id);
            }
        }
    }

    public IReadOnlyList<SsoProviderInfo> ListEnabled() =>
        Describe().Where(provider => provider.IsReady).Select(provider => new SsoProviderInfo(provider.Id, provider.DisplayName)).ToArray();

    public SsoProviderInfo? Find(string provider)
    {
        var match = Describe().FirstOrDefault(item => item.Id == provider && item.IsReady);
        return match is null ? null : new SsoProviderInfo(match.Id, match.DisplayName);
    }

    public string DisplayName(string provider) =>
        Describe().FirstOrDefault(item => item.Id == provider)?.DisplayName ?? provider;

    public async Task<Uri> CreateAuthorizationUrlAsync(SsoAuthorizeRequest request, CancellationToken cancellationToken = default)
    {
        var provider = Required(request.Provider);
        var configuration = await GetConfigurationAsync(provider, cancellationToken);
        if (!EndpointAllowed(configuration.AuthorizationEndpoint))
        {
            throw new AppException(ErrorCodes.SsoProviderError, "The identity provider could not start sign-in");
        }

        var query = new Dictionary<string, string?>
        {
            ["response_type"] = "code",
            ["client_id"] = provider.ClientId,
            ["redirect_uri"] = provider.RedirectUri,
            ["scope"] = "openid profile email",
            ["state"] = request.State,
            ["nonce"] = request.Nonce,
            ["code_challenge"] = SecretTokens.CodeChallenge(request.CodeVerifier),
            ["code_challenge_method"] = "S256",
            ["response_mode"] = "query"
        };
        if (request.SelectAccount)
        {
            query["prompt"] = "select_account";
        }

        return new Uri(QueryHelpers.AddQueryString(configuration.AuthorizationEndpoint, query));
    }

    public async Task<VerifiedExternalIdentity> RedeemAuthorizationCodeAsync(
        SsoRedeemRequest request,
        CancellationToken cancellationToken = default)
    {
        var provider = Required(request.Provider);
        var configuration = await GetConfigurationAsync(provider, cancellationToken);
        if (!EndpointAllowed(configuration.TokenEndpoint))
        {
            throw new AppException(ErrorCodes.SsoProviderError, "The identity provider rejected the sign-in");
        }

        var idToken = await ExchangeCodeAsync(provider, configuration.TokenEndpoint, request, cancellationToken);
        var principal = await ValidateIdTokenAsync(provider, configuration, idToken, cancellationToken);
        if (!FixedEquals(principal.FindFirst("nonce")?.Value, request.ExpectedNonce))
        {
            _logger.LogWarning("SSO nonce was rejected for provider {Provider}", provider.Id);
            throw new AppException(ErrorCodes.SsoInvalid, "The identity provider response could not be verified");
        }

        var subject = principal.FindFirst("sub")?.Value?.Trim();
        var issuer = principal.FindFirst("iss")?.Value?.Trim();
        if (string.IsNullOrWhiteSpace(subject) || string.IsNullOrWhiteSpace(issuer) || subject.Length > 450 || issuer.Length > 500)
        {
            throw new AppException(ErrorCodes.SsoInvalid, "The identity provider response could not be verified");
        }

        var authorizedParty = principal.FindFirst("azp")?.Value;
        if (!string.IsNullOrEmpty(authorizedParty) && !string.Equals(authorizedParty, provider.ClientId, StringComparison.Ordinal))
        {
            _logger.LogWarning("SSO audience party was rejected for provider {Provider}", provider.Id);
            throw new AppException(ErrorCodes.SsoInvalid, "The identity provider response could not be verified");
        }

        if (provider.Id == SsoProviders.Microsoft && principal.FindFirst("ver")?.Value != "2.0")
        {
            throw new AppException(ErrorCodes.SsoInvalid, "The identity provider response could not be verified");
        }

        var (email, fromPreferred) = ReadEmail(principal);
        return new VerifiedExternalIdentity(
            provider.Id,
            issuer,
            subject,
            email,
            IsEmailVerified(provider, principal, fromPreferred, email),
            ReadName(principal));
    }

    public async Task<Uri?> CreateLogoutUrlAsync(string providerName, CancellationToken cancellationToken = default)
    {
        var provider = Describe().FirstOrDefault(item => item.Id == providerName && item.IsReady);
        if (provider is null)
        {
            return null;
        }

        var configuration = await GetConfigurationAsync(provider, cancellationToken);
        if (string.IsNullOrWhiteSpace(configuration.EndSessionEndpoint) || !EndpointAllowed(configuration.EndSessionEndpoint))
        {
            return null;
        }

        var query = new Dictionary<string, string?>
        {
            ["client_id"] = provider.ClientId
        };
        if (SsoConfiguration.IsAllowedAbsoluteUri(provider.PostLogoutRedirectUri, _environment.IsDevelopment()))
        {
            query["post_logout_redirect_uri"] = provider.PostLogoutRedirectUri;
        }

        return new Uri(QueryHelpers.AddQueryString(configuration.EndSessionEndpoint, query));
    }

    private ProviderSetup Required(string provider) =>
        Describe().FirstOrDefault(item => item.Id == provider && item.IsReady)
        ?? throw new AppException(ErrorCodes.SsoDisabled, "That sign-in method is not available");

    private async Task<OpenIdConnectConfiguration> GetConfigurationAsync(ProviderSetup provider, CancellationToken cancellationToken)
    {
        try
        {
            var manager = _metadata.GetOrAdd(provider.MetadataAddress, address =>
            {
                var retriever = new HttpDocumentRetriever
                {
                    RequireHttps = address.StartsWith("https://", StringComparison.OrdinalIgnoreCase)
                };
                return new ConfigurationManager<OpenIdConnectConfiguration>(
                    address,
                    new OpenIdConnectConfigurationRetriever(),
                    retriever);
            });
            return await manager.GetConfigurationAsync(cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning("SSO metadata could not be loaded for provider {Provider}: {Reason}", provider.Id, ex.GetType().Name);
            throw new AppException(ErrorCodes.SsoProviderError, "The identity provider could not be reached");
        }
    }

    private async Task<string> ExchangeCodeAsync(
        ProviderSetup provider,
        string tokenEndpoint,
        SsoRedeemRequest request,
        CancellationToken cancellationToken)
    {
        var client = _httpClientFactory.CreateClient(HttpClientName);
        using var message = new HttpRequestMessage(HttpMethod.Post, tokenEndpoint);
        message.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        message.Content = new FormUrlEncodedContent(new Dictionary<string, string>
        {
            ["grant_type"] = "authorization_code",
            ["code"] = request.Code,
            ["redirect_uri"] = provider.RedirectUri,
            ["client_id"] = provider.ClientId,
            ["client_secret"] = provider.ClientSecret,
            ["code_verifier"] = request.CodeVerifier
        });

        using var response = await client.SendAsync(message, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (body.Length > 100_000)
        {
            throw new AppException(ErrorCodes.SsoProviderError, "The identity provider rejected the sign-in");
        }

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogWarning(
                "SSO token endpoint returned {Status} {OAuthError} for provider {Provider}",
                (int)response.StatusCode,
                ReadOAuthError(body),
                provider.Id);
            throw new AppException(ErrorCodes.SsoProviderError, "The identity provider rejected the sign-in");
        }

        try
        {
            using var document = JsonDocument.Parse(body);
            if (!document.RootElement.TryGetProperty("id_token", out var token) || token.ValueKind != JsonValueKind.String)
            {
                throw new AppException(ErrorCodes.SsoProviderError, "The identity provider rejected the sign-in");
            }

            var value = token.GetString();
            if (string.IsNullOrWhiteSpace(value))
            {
                throw new AppException(ErrorCodes.SsoProviderError, "The identity provider rejected the sign-in");
            }

            return value;
        }
        catch (AppException)
        {
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogWarning("SSO token response could not be read for provider {Provider}: {Reason}", provider.Id, ex.GetType().Name);
            throw new AppException(ErrorCodes.SsoProviderError, "The identity provider rejected the sign-in");
        }
    }

    private async Task<ClaimsPrincipal> ValidateIdTokenAsync(
        ProviderSetup provider,
        OpenIdConnectConfiguration configuration,
        string idToken,
        CancellationToken cancellationToken)
    {
        var handler = new JwtSecurityTokenHandler
        {
            MapInboundClaims = false
        };
        var parameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidAudience = provider.ClientId,
            ValidateLifetime = true,
            RequireExpirationTime = true,
            ValidateIssuerSigningKey = true,
            RequireSignedTokens = true,
            IssuerSigningKeys = configuration.SigningKeys,
            ValidAlgorithms = AllowedAlgorithms,
            ClockSkew = TimeSpan.FromMinutes(2),
            NameClaimType = "name"
        };
        if (provider.MicrosoftTenant is not null)
        {
            var tenant = provider.MicrosoftTenant;
            parameters.IssuerValidator = (issuer, token, _) => ValidateMicrosoftIssuer(issuer, token, tenant);
        }
        else
        {
            parameters.ValidIssuers = provider.ValidIssuers(configuration);
        }

        var result = await handler.ValidateTokenAsync(idToken, parameters);
        if (!result.IsValid || result.ClaimsIdentity is null)
        {
            _logger.LogWarning(
                "SSO ID token was rejected for provider {Provider}: {Reason}",
                provider.Id,
                result.Exception?.GetType().Name ?? "invalid");
            throw new AppException(ErrorCodes.SsoInvalid, "The identity provider response could not be verified");
        }

        return new ClaimsPrincipal(result.ClaimsIdentity);
    }

    private static string ValidateMicrosoftIssuer(string issuer, SecurityToken token, string tenant)
    {
        if (token is not JwtSecurityToken jwt)
        {
            throw new SecurityTokenInvalidIssuerException("issuer");
        }

        var tenantId = jwt.Claims.FirstOrDefault(claim => claim.Type == "tid")?.Value;
        if (string.IsNullOrWhiteSpace(tenantId) || !Guid.TryParse(tenantId, out _))
        {
            throw new SecurityTokenInvalidIssuerException("issuer");
        }

        if (Guid.TryParse(tenant, out var configured))
        {
            if (!Guid.Parse(tenantId).Equals(configured))
            {
                throw new SecurityTokenInvalidIssuerException("issuer");
            }
        }
        else if (tenant.Equals("consumers", StringComparison.OrdinalIgnoreCase))
        {
            if (!tenantId.Equals(MicrosoftAccountTenant, StringComparison.OrdinalIgnoreCase))
            {
                throw new SecurityTokenInvalidIssuerException("issuer");
            }
        }
        else if (tenant.Equals("organizations", StringComparison.OrdinalIgnoreCase))
        {
            if (tenantId.Equals(MicrosoftAccountTenant, StringComparison.OrdinalIgnoreCase))
            {
                throw new SecurityTokenInvalidIssuerException("issuer");
            }
        }
        else if (!tenant.Equals("common", StringComparison.OrdinalIgnoreCase))
        {
            throw new SecurityTokenInvalidIssuerException("issuer");
        }

        var expected = $"https://login.microsoftonline.com/{tenantId}/v2.0";
        if (!string.Equals(issuer.TrimEnd('/'), expected, StringComparison.OrdinalIgnoreCase))
        {
            throw new SecurityTokenInvalidIssuerException("issuer");
        }

        return issuer;
    }

    private IReadOnlyList<ProviderSetup> Describe()
    {
        var options = _options.Value;
        var redirect = options.RedirectUri?.Trim() ?? string.Empty;
        var redirectReady = EndpointAllowed(redirect);
        var postLogout = options.PostLogoutRedirectUri?.Trim() ?? string.Empty;
        return
        [
            Build(
                SsoProviders.Google,
                "Google",
                options.Google.Enabled,
                options.Google.ClientId,
                options.Google.ClientSecret,
                string.IsNullOrWhiteSpace(options.Google.Issuer) ? "https://accounts.google.com" : options.Google.Issuer,
                redirect,
                redirectReady,
                postLogout,
                microsoftTenant: null,
                google: true),
            Build(
                SsoProviders.Microsoft,
                "Microsoft",
                options.Microsoft.Enabled,
                options.Microsoft.ClientId,
                options.Microsoft.ClientSecret,
                MicrosoftIssuer(options.Microsoft.TenantId),
                redirect,
                redirectReady && ValidTenant(options.Microsoft.TenantId),
                postLogout,
                string.IsNullOrWhiteSpace(options.Microsoft.TenantId) ? "common" : options.Microsoft.TenantId.Trim(),
                google: false),
            Build(
                SsoProviders.Oidc,
                CleanDisplayName(options.Oidc.DisplayName),
                options.Oidc.Enabled,
                options.Oidc.ClientId,
                options.Oidc.ClientSecret,
                options.Oidc.Issuer,
                redirect,
                redirectReady,
                postLogout,
                microsoftTenant: null,
                google: false)
        ];
    }

    private ProviderSetup Build(
        string id,
        string displayName,
        bool enabled,
        string? clientId,
        string? clientSecret,
        string? issuer,
        string redirect,
        bool redirectReady,
        string postLogout,
        string? microsoftTenant,
        bool google)
    {
        var normalizedIssuer = issuer?.Trim().TrimEnd('/') ?? string.Empty;
        var ready = enabled
            && redirectReady
            && !string.IsNullOrWhiteSpace(clientId)
            && !string.IsNullOrWhiteSpace(clientSecret)
            && EndpointAllowed(normalizedIssuer);
        return new ProviderSetup(
            id,
            displayName,
            enabled,
            ready,
            clientId?.Trim() ?? string.Empty,
            clientSecret?.Trim() ?? string.Empty,
            normalizedIssuer,
            normalizedIssuer + "/.well-known/openid-configuration",
            redirect,
            postLogout,
            microsoftTenant,
            google);
    }

    private bool EndpointAllowed(string? value)
    {
        if (string.IsNullOrWhiteSpace(value) || !Uri.TryCreate(value, UriKind.Absolute, out var uri))
        {
            return false;
        }

        if (uri.Scheme == Uri.UriSchemeHttps)
        {
            return true;
        }

        return _environment.IsDevelopment() && uri.Scheme == Uri.UriSchemeHttp && uri.IsLoopback;
    }

    private static bool ValidTenant(string? tenant)
    {
        var value = tenant?.Trim();
        return value is "common" or "organizations" or "consumers" || Guid.TryParse(value, out _);
    }

    private static string MicrosoftIssuer(string? tenant)
    {
        var value = string.IsNullOrWhiteSpace(tenant) ? "common" : tenant.Trim();
        return $"https://login.microsoftonline.com/{value}/v2.0";
    }

    private static string CleanDisplayName(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return "Single sign-on";
        }

        var cleaned = new string(value.Where(character => !char.IsControl(character)).ToArray()).Trim();
        if (cleaned.Length == 0)
        {
            return "Single sign-on";
        }

        return cleaned.Length > 40 ? cleaned[..40] : cleaned;
    }

    private static (string? Email, bool FromPreferred) ReadEmail(ClaimsPrincipal principal)
    {
        var email = principal.FindFirst("email")?.Value?.Trim();
        if (!string.IsNullOrWhiteSpace(email))
        {
            return (email, false);
        }

        var preferred = principal.FindFirst("preferred_username")?.Value?.Trim();
        if (!string.IsNullOrWhiteSpace(preferred) && preferred.Contains('@', StringComparison.Ordinal) && !preferred.Contains(' ', StringComparison.Ordinal))
        {
            return (preferred, true);
        }

        return (null, false);
    }

    private static bool IsEmailVerified(ProviderSetup provider, ClaimsPrincipal principal, bool fromPreferred, string? email)
    {
        if (string.IsNullOrWhiteSpace(email))
        {
            return false;
        }

        var asserted = BoolClaim(principal, "email_verified") || BoolClaim(principal, "xms_edov");
        if (provider.Id == SsoProviders.Google)
        {
            return !fromPreferred && BoolClaim(principal, "email_verified");
        }

        if (provider.Id == SsoProviders.Microsoft && Guid.TryParse(provider.MicrosoftTenant, out _))
        {
            return true;
        }

        if (provider.Id == SsoProviders.Microsoft)
        {
            return asserted && !fromPreferred;
        }

        return !fromPreferred && BoolClaim(principal, "email_verified");
    }

    private static string? ReadName(ClaimsPrincipal principal)
    {
        var name = principal.FindFirst("name")?.Value;
        if (!string.IsNullOrWhiteSpace(name))
        {
            return name;
        }

        var given = principal.FindFirst("given_name")?.Value;
        var family = principal.FindFirst("family_name")?.Value;
        var combined = $"{given} {family}".Trim();
        return string.IsNullOrWhiteSpace(combined) ? null : combined;
    }

    private static bool BoolClaim(ClaimsPrincipal principal, string type)
    {
        var value = principal.FindFirst(type)?.Value;
        return value is "true" or "True" or "1";
    }

    private static bool FixedEquals(string? left, string? right)
    {
        if (string.IsNullOrEmpty(left) || string.IsNullOrEmpty(right))
        {
            return false;
        }

        var a = System.Text.Encoding.UTF8.GetBytes(left);
        var b = System.Text.Encoding.UTF8.GetBytes(right);
        return a.Length == b.Length && System.Security.Cryptography.CryptographicOperations.FixedTimeEquals(a, b);
    }

    private static string ReadOAuthError(string body)
    {
        try
        {
            using var document = JsonDocument.Parse(body);
            if (document.RootElement.TryGetProperty("error", out var error) && error.ValueKind == JsonValueKind.String)
            {
                var code = error.GetString();
                if (!string.IsNullOrWhiteSpace(code) && code.Length <= 64 && code.All(character => char.IsLetterOrDigit(character) || character is '_' or '-'))
                {
                    return code;
                }
            }
        }
        catch (JsonException)
        {
            return "unknown";
        }

        return "unknown";
    }

    private sealed record ProviderSetup(
        string Id,
        string DisplayName,
        bool Enabled,
        bool IsReady,
        string ClientId,
        string ClientSecret,
        string Issuer,
        string MetadataAddress,
        string RedirectUri,
        string PostLogoutRedirectUri,
        string? MicrosoftTenant,
        bool Google)
    {
        public IEnumerable<string> ValidIssuers(OpenIdConnectConfiguration configuration)
        {
            if (Google)
            {
                return ["https://accounts.google.com", "accounts.google.com"];
            }

            if (MicrosoftTenant is not null)
            {
                return [configuration.Issuer];
            }

            var issuer = string.IsNullOrWhiteSpace(configuration.Issuer) ? Issuer : configuration.Issuer.Trim();
            return [issuer, issuer.TrimEnd('/')];
        }
    }
}
