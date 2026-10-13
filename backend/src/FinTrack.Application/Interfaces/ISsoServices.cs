using FinTrack.Application.DTOs.Auth;

namespace FinTrack.Application.Interfaces;

public interface ISsoAuthService
{
    Task<IReadOnlyList<SsoProviderDto>> GetProvidersAsync(CancellationToken cancellationToken = default);
    Task<SsoStartResponse> StartAsync(SsoStartRequest request, Guid? authenticatedUserId, CancellationToken cancellationToken = default);
    Task<string?> CompleteCallbackAsync(string? code, string? state, string? error, CancellationToken cancellationToken = default);
    Task<SsoResultDto> ExchangeAsync(SsoExchangeRequest request, CancellationToken cancellationToken = default);
    Task<SsoResultDto> LinkWithPasswordAsync(SsoLinkRequest request, CancellationToken cancellationToken = default);
    Task<AuthMethodsDto> GetMethodsAsync(CancellationToken cancellationToken = default);
    Task UnlinkAsync(string provider, CancellationToken cancellationToken = default);
    Task<SsoLogoutResponse> CreateLogoutAsync(CancellationToken cancellationToken = default);
}

public interface ISsoConfiguration
{
    bool AllowRegistration { get; }
    string AppCallbackUri { get; }
    string PostLogoutRedirectUri { get; }
    bool IsAppCallbackAllowed { get; }
}

public interface IIdentityProviderClient
{
    IReadOnlyList<SsoProviderInfo> ListEnabled();
    SsoProviderInfo? Find(string provider);
    string DisplayName(string provider);
    Task<Uri> CreateAuthorizationUrlAsync(SsoAuthorizeRequest request, CancellationToken cancellationToken = default);
    Task<VerifiedExternalIdentity> RedeemAuthorizationCodeAsync(SsoRedeemRequest request, CancellationToken cancellationToken = default);
    Task<Uri?> CreateLogoutUrlAsync(string provider, CancellationToken cancellationToken = default);
}

public sealed record SsoProviderInfo(string Id, string DisplayName);

public sealed record SsoAuthorizeRequest(
    string Provider,
    string State,
    string Nonce,
    string CodeVerifier,
    bool SelectAccount);

public sealed record SsoRedeemRequest(
    string Provider,
    string Code,
    string CodeVerifier,
    string ExpectedNonce);

public sealed record VerifiedExternalIdentity(
    string Provider,
    string Issuer,
    string Subject,
    string? Email,
    bool EmailVerified,
    string? Name);
