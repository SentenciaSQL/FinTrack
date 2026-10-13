using AutoMapper;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using FinTrack.Application.Common;
using FinTrack.Application.DTOs.Auth;
using FinTrack.Application.Interfaces;
using FinTrack.Domain.Entities;

namespace FinTrack.Application.Services;

public class SsoAuthService : ISsoAuthService
{
    private static readonly TimeSpan ChallengeLifetime = TimeSpan.FromMinutes(10);
    private static readonly TimeSpan ExchangeLifetime = TimeSpan.FromMinutes(2);
    private const int MaxLinkAttempts = 5;

    private readonly IFinTrackDbContext _db;
    private readonly IIdentityProviderClient _providers;
    private readonly ISsoConfiguration _configuration;
    private readonly IJwtTokenService _jwt;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IDateTimeProvider _clock;
    private readonly IMapper _mapper;
    private readonly ICurrentUser _currentUser;
    private readonly IValidator<SsoStartRequest> _startValidator;
    private readonly IValidator<SsoExchangeRequest> _exchangeValidator;
    private readonly IValidator<SsoLinkRequest> _linkValidator;
    private readonly ILogger<SsoAuthService> _logger;

    public SsoAuthService(
        IFinTrackDbContext db,
        IIdentityProviderClient providers,
        ISsoConfiguration configuration,
        IJwtTokenService jwt,
        IPasswordHasher passwordHasher,
        IDateTimeProvider clock,
        IMapper mapper,
        ICurrentUser currentUser,
        IValidator<SsoStartRequest> startValidator,
        IValidator<SsoExchangeRequest> exchangeValidator,
        IValidator<SsoLinkRequest> linkValidator,
        ILogger<SsoAuthService> logger)
    {
        _db = db;
        _providers = providers;
        _configuration = configuration;
        _jwt = jwt;
        _passwordHasher = passwordHasher;
        _clock = clock;
        _mapper = mapper;
        _currentUser = currentUser;
        _startValidator = startValidator;
        _exchangeValidator = exchangeValidator;
        _linkValidator = linkValidator;
        _logger = logger;
    }

    public Task<IReadOnlyList<SsoProviderDto>> GetProvidersAsync(CancellationToken cancellationToken = default)
    {
        IReadOnlyList<SsoProviderDto> providers = _providers.ListEnabled()
            .Select(provider => new SsoProviderDto { Id = provider.Id, DisplayName = provider.DisplayName })
            .ToArray();
        return Task.FromResult(providers);
    }

    public async Task<SsoStartResponse> StartAsync(
        SsoStartRequest request,
        Guid? authenticatedUserId,
        CancellationToken cancellationToken = default)
    {
        await _startValidator.ValidateAndThrowAppAsync(request, cancellationToken);
        var provider = SsoProviders.Normalize(request.Provider)
            ?? throw new AppException(ErrorCodes.SsoDisabled, "That sign-in method is not available");
        if (_providers.Find(provider) is null)
        {
            throw new AppException(ErrorCodes.SsoDisabled, "That sign-in method is not available");
        }

        var linkUserId = await ResolveLinkUserAsync(request.Intent, authenticatedUserId, provider, cancellationToken);
        await _db.DeleteExpiredChallengesAsync(_clock.UtcNow, cancellationToken);

        var now = _clock.UtcNow;
        var state = SecretTokens.Create();
        var nonce = SecretTokens.Create();
        var verifier = SecretTokens.Create();
        var challenge = new SsoChallenge
        {
            Id = Guid.NewGuid(),
            StateHash = SecretTokens.Sha256Hex(state),
            Nonce = nonce,
            CodeVerifier = verifier,
            Provider = provider,
            Intent = linkUserId is null ? SsoIntents.SignIn : SsoIntents.Link,
            ReturnPath = ReturnPaths.Normalize(request.ReturnPath),
            LinkUserId = linkUserId,
            PreferredLanguage = request.PreferredLanguage is "en" or "es" ? request.PreferredLanguage : "es",
            PreferredCurrency = request.PreferredCurrency is "DOP" or "USD" or "EUR" ? request.PreferredCurrency : "DOP",
            CreatedAt = now,
            ExpiresAt = now.Add(ChallengeLifetime),
            Outcome = SsoOutcomes.Pending
        };

        _db.SsoChallenges.Add(challenge);
        await _db.SaveChangesAsync(cancellationToken);

        try
        {
            var url = await _providers.CreateAuthorizationUrlAsync(
                new SsoAuthorizeRequest(provider, state, nonce, verifier, linkUserId is not null),
                cancellationToken);
            _logger.LogInformation("Started SSO challenge {ChallengeId} for provider {Provider}", challenge.Id, provider);
            return new SsoStartResponse
            {
                AuthorizationUrl = url.ToString(),
                State = state
            };
        }
        catch (AppException)
        {
            _db.SsoChallenges.Remove(challenge);
            await _db.SaveChangesAsync(cancellationToken);
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(
                "SSO authorization URL could not be created for provider {Provider}: {Reason}",
                provider,
                ex.GetType().Name);
            _db.SsoChallenges.Remove(challenge);
            await _db.SaveChangesAsync(cancellationToken);
            throw new AppException(ErrorCodes.SsoProviderError, "The identity provider could not start sign-in");
        }
    }

    public async Task<string?> CompleteCallbackAsync(
        string? code,
        string? state,
        string? error,
        CancellationToken cancellationToken = default)
    {
        if (!_configuration.IsAppCallbackAllowed)
        {
            _logger.LogError("SSO app callback URI is not allowed");
            return null;
        }

        if (string.IsNullOrWhiteSpace(state))
        {
            return RedirectToApp(("error", ErrorCodes.SsoInvalid));
        }

        var stateHash = SecretTokens.Sha256Hex(state);
        var existing = await _db.SsoChallenges
            .AsNoTracking()
            .FirstOrDefaultAsync(challenge => challenge.StateHash == stateHash, cancellationToken);
        if (existing is null)
        {
            return RedirectToApp(("error", ErrorCodes.SsoInvalid));
        }

        if (existing.AuthorizedAt is not null || existing.ExpiresAt <= _clock.UtcNow)
        {
            return RedirectToApp(("error", ErrorCodes.SsoExpired));
        }

        var claimed = await _db.ClaimChallengeAsync(existing.Id, _clock.UtcNow, cancellationToken);
        if (claimed == 0)
        {
            return RedirectToApp(("error", ErrorCodes.SsoExpired));
        }

        var challenge = await _db.SsoChallenges.FirstAsync(item => item.Id == existing.Id, cancellationToken);
        var providerError = MapProviderError(error);
        if (providerError is not null || string.IsNullOrWhiteSpace(code))
        {
            return await FailAsync(challenge, providerError ?? ErrorCodes.SsoInvalid, cancellationToken);
        }

        VerifiedExternalIdentity identity;
        try
        {
            identity = await _providers.RedeemAuthorizationCodeAsync(
                new SsoRedeemRequest(challenge.Provider, code, challenge.CodeVerifier, challenge.Nonce),
                cancellationToken);
        }
        catch (AppException ex)
        {
            _logger.LogWarning("SSO callback rejected for provider {Provider} with {Code}", challenge.Provider, ex.Code);
            return await FailAsync(challenge, ex.Code, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "SSO callback failed for provider {Provider}", challenge.Provider);
            return await FailAsync(challenge, ErrorCodes.SsoProviderError, cancellationToken);
        }

        challenge.CodeVerifier = string.Empty;
        challenge.Nonce = string.Empty;
        try
        {
            await ResolveIdentityAsync(challenge, identity, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(
                "SSO account resolution failed for provider {Provider}: {Reason}",
                challenge.Provider,
                ex.GetType().Name);
            _db.DetachAll();
            challenge = await _db.SsoChallenges.FirstAsync(item => item.Id == existing.Id, cancellationToken);
            return await FailAsync(challenge, ErrorCodes.SsoProviderError, cancellationToken);
        }

        if (challenge.Outcome == SsoOutcomes.Error)
        {
            return await FailAsync(challenge, challenge.ErrorCode ?? ErrorCodes.SsoInvalid, cancellationToken);
        }

        try
        {
            return await IssueExchangeCodeAsync(challenge, cancellationToken);
        }
        catch (DbUpdateException)
        {
            var recovered = await RecoverCreateConflictAsync(challenge.Id, identity, challenge.Email, cancellationToken);
            if (recovered.Outcome == SsoOutcomes.Error)
            {
                return await FailAsync(recovered, recovered.ErrorCode ?? ErrorCodes.SsoInvalid, cancellationToken);
            }

            return await IssueExchangeCodeAsync(recovered, cancellationToken);
        }
    }

    public async Task<SsoResultDto> ExchangeAsync(SsoExchangeRequest request, CancellationToken cancellationToken = default)
    {
        await _exchangeValidator.ValidateAndThrowAppAsync(request, cancellationToken);
        var now = _clock.UtcNow;
        var challenge = await _db.SsoChallenges.FirstOrDefaultAsync(
            item => item.ExchangeCodeHash == SecretTokens.Sha256Hex(request.Code)
                    && item.StateHash == SecretTokens.Sha256Hex(request.State),
            cancellationToken);

        if (challenge is null
            || challenge.CompletedAt is not null
            || challenge.ExchangeExpiresAt is null
            || challenge.ExchangeExpiresAt <= now
            || challenge.ExpiresAt <= now)
        {
            throw new AppException(ErrorCodes.SsoExpired, "The sign-in attempt expired");
        }

        if (challenge.Outcome == SsoOutcomes.LinkRequired)
        {
            var canUsePassword = await CanUsePasswordAsync(challenge.ResolvedUserId, cancellationToken);
            challenge.CompletedAt = now;
            if (!canUsePassword)
            {
                challenge.ErrorCode = ErrorCodes.SsoLinkUnavailable;
                await _db.SaveChangesAsync(cancellationToken);
                throw new AppException(ErrorCodes.SsoLinkUnavailable, "Sign in with the existing method, then connect this provider from Profile");
            }

            var linkToken = SecretTokens.Create();
            challenge.LinkTokenHash = SecretTokens.Sha256Hex(linkToken);
            await _db.SaveChangesAsync(cancellationToken);
            return new SsoResultDto
            {
                Status = SsoStatuses.LinkRequired,
                ReturnPath = challenge.ReturnPath,
                LinkToken = linkToken,
                Email = challenge.Email,
                Provider = challenge.Provider,
                ProviderDisplayName = _providers.DisplayName(challenge.Provider),
                CanUsePassword = true
            };
        }

        challenge.CompletedAt = now;
        if (challenge.Outcome == SsoOutcomes.Linked)
        {
            await _db.SaveChangesAsync(cancellationToken);
            return new SsoResultDto
            {
                Status = SsoStatuses.Linked,
                ReturnPath = challenge.ReturnPath,
                Provider = challenge.Provider,
                ProviderDisplayName = _providers.DisplayName(challenge.Provider),
                Email = challenge.Email
            };
        }

        if (challenge.Outcome != SsoOutcomes.Authenticated || challenge.ResolvedUserId is null)
        {
            challenge.ErrorCode = ErrorCodes.SsoInvalid;
            await _db.SaveChangesAsync(cancellationToken);
            throw new AppException(ErrorCodes.SsoInvalid, "Sign-in could not be completed");
        }

        var user = await _db.Users.FirstOrDefaultAsync(item => item.Id == challenge.ResolvedUserId, cancellationToken);
        if (user is null)
        {
            challenge.ErrorCode = ErrorCodes.SsoInvalid;
            await _db.SaveChangesAsync(cancellationToken);
            throw new AppException(ErrorCodes.SsoInvalid, "Sign-in could not be completed");
        }

        await _db.SaveChangesAsync(cancellationToken);
        return AuthenticatedResult(user, challenge.ReturnPath);
    }

    public async Task<SsoResultDto> LinkWithPasswordAsync(SsoLinkRequest request, CancellationToken cancellationToken = default)
    {
        await _linkValidator.ValidateAndThrowAppAsync(request, cancellationToken);
        var now = _clock.UtcNow;
        var challenge = await _db.SsoChallenges.FirstOrDefaultAsync(
            item => item.LinkTokenHash == SecretTokens.Sha256Hex(request.LinkToken),
            cancellationToken);

        if (challenge is null
            || challenge.Outcome != SsoOutcomes.LinkRequired
            || challenge.LinkConsumedAt is not null
            || challenge.ExpiresAt <= now
            || challenge.ResolvedUserId is null
            || string.IsNullOrWhiteSpace(challenge.Issuer)
            || string.IsNullOrWhiteSpace(challenge.Subject))
        {
            throw new AppException(ErrorCodes.SsoExpired, "The sign-in attempt expired");
        }

        challenge.LinkAttempts += 1;
        if (challenge.LinkAttempts > MaxLinkAttempts)
        {
            challenge.LinkConsumedAt = now;
            challenge.ErrorCode = ErrorCodes.SsoExpired;
            await _db.SaveChangesAsync(cancellationToken);
            throw new AppException(ErrorCodes.SsoExpired, "The sign-in attempt expired");
        }

        await _db.SaveChangesAsync(cancellationToken);

        var user = await _db.Users.FirstOrDefaultAsync(item => item.Id == challenge.ResolvedUserId, cancellationToken);
        if (user is null
            || !PasswordHashes.IsSet(user.PasswordHash)
            || !string.Equals(user.Email, challenge.Email, StringComparison.Ordinal)
            || !_passwordHasher.Verify(request.Password, user.PasswordHash))
        {
            throw new UnauthorizedException("Invalid email or password");
        }

        var taken = await _db.ExternalLogins.AnyAsync(
            login => login.Issuer == challenge.Issuer && login.Subject == challenge.Subject,
            cancellationToken);
        if (taken)
        {
            challenge.LinkConsumedAt = now;
            challenge.ErrorCode = ErrorCodes.SsoIdentityInUse;
            await _db.SaveChangesAsync(cancellationToken);
            throw new ConflictException(ErrorCodes.SsoIdentityInUse, "That sign-in is already linked to another account");
        }

        var providerTaken = await _db.ExternalLogins.AnyAsync(
            login => login.UserId == user.Id && login.Provider == challenge.Provider,
            cancellationToken);
        if (providerTaken)
        {
            challenge.LinkConsumedAt = now;
            await _db.SaveChangesAsync(cancellationToken);
            throw new ConflictException(ErrorCodes.SsoProviderAlreadyLinked, "This account already has that provider connected");
        }

        _db.ExternalLogins.Add(new ExternalLogin
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            Provider = challenge.Provider,
            Issuer = challenge.Issuer,
            Subject = challenge.Subject,
            Email = challenge.Email,
            EmailVerified = challenge.EmailVerified,
            CreatedAt = now,
            LastUsedAt = now
        });
        challenge.LinkConsumedAt = now;
        await _db.SaveChangesAsync(cancellationToken);
        _logger.LogInformation("Linked SSO provider {Provider} to an existing account", challenge.Provider);
        return AuthenticatedResult(user, challenge.ReturnPath);
    }

    public async Task<AuthMethodsDto> GetMethodsAsync(CancellationToken cancellationToken = default)
    {
        var user = await _db.Users.FirstAsync(item => item.Id == _currentUser.UserId, cancellationToken);
        var logins = await _db.ExternalLogins
            .Where(login => login.UserId == user.Id)
            .OrderBy(login => login.CreatedAt)
            .ToListAsync(cancellationToken);

        return new AuthMethodsDto
        {
            HasPassword = PasswordHashes.IsSet(user.PasswordHash),
            Methods = logins.Select(login => new LinkedAuthMethodDto
            {
                Provider = login.Provider,
                DisplayName = _providers.DisplayName(login.Provider),
                Email = login.Email,
                LinkedAt = login.CreatedAt
            }).ToArray(),
            AvailableProviders = _providers.ListEnabled()
                .Select(provider => new SsoProviderDto { Id = provider.Id, DisplayName = provider.DisplayName })
                .ToArray()
        };
    }

    public async Task UnlinkAsync(string provider, CancellationToken cancellationToken = default)
    {
        var name = SsoProviders.Normalize(provider)
            ?? throw new NotFoundException("Sign-in method not found");
        var user = await _db.Users.FirstAsync(item => item.Id == _currentUser.UserId, cancellationToken);
        var login = await _db.ExternalLogins.FirstOrDefaultAsync(
            item => item.UserId == user.Id && item.Provider == name,
            cancellationToken) ?? throw new NotFoundException("Sign-in method not found");

        var remaining = await _db.ExternalLogins.CountAsync(item => item.UserId == user.Id, cancellationToken);
        if (remaining <= 1 && !PasswordHashes.IsSet(user.PasswordHash))
        {
            throw new ConflictException(ErrorCodes.SsoLastSignInMethod, "Keep a password or another sign-in method before disconnecting this one");
        }

        _db.ExternalLogins.Remove(login);
        await _db.SaveChangesAsync(cancellationToken);
        _logger.LogInformation("Unlinked SSO provider {Provider}", name);
    }

    public async Task<SsoLogoutResponse> CreateLogoutAsync(CancellationToken cancellationToken = default)
    {
        var login = await _db.ExternalLogins
            .Where(item => item.UserId == _currentUser.UserId)
            .OrderByDescending(item => item.LastUsedAt)
            .FirstOrDefaultAsync(cancellationToken);
        if (login is null || _providers.Find(login.Provider) is null)
        {
            return new SsoLogoutResponse();
        }

        try
        {
            var url = await _providers.CreateLogoutUrlAsync(login.Provider, cancellationToken);
            return new SsoLogoutResponse { Url = url?.ToString() };
        }
        catch (Exception ex)
        {
            _logger.LogWarning(
            "SSO logout URL could not be created for provider {Provider}: {Reason}",
            login.Provider,
            ex.GetType().Name);
            return new SsoLogoutResponse();
        }
    }

    private async Task<Guid?> ResolveLinkUserAsync(
        string intent,
        Guid? authenticatedUserId,
        string provider,
        CancellationToken cancellationToken)
    {
        if (intent != SsoIntents.Link)
        {
            return null;
        }

        if (authenticatedUserId is null)
        {
            throw new UnauthorizedException("Authentication is required");
        }

        var userExists = await _db.Users.AnyAsync(user => user.Id == authenticatedUserId, cancellationToken);
        if (!userExists)
        {
            throw new UnauthorizedException("Authentication is required");
        }

        var already = await _db.ExternalLogins.AnyAsync(
            login => login.UserId == authenticatedUserId && login.Provider == provider,
            cancellationToken);
        if (already)
        {
            throw new ConflictException(ErrorCodes.SsoProviderAlreadyLinked, "This account already has that provider connected");
        }

        return authenticatedUserId;
    }

    private async Task ResolveIdentityAsync(
        SsoChallenge challenge,
        VerifiedExternalIdentity identity,
        CancellationToken cancellationToken)
    {
        if (identity.Issuer.Length > 500 || identity.Subject.Length > 450)
        {
            challenge.Outcome = SsoOutcomes.Error;
            challenge.ErrorCode = ErrorCodes.SsoInvalid;
            return;
        }

        var email = NormalizeEmail(identity.Email);
        challenge.Issuer = identity.Issuer;
        challenge.Subject = identity.Subject;
        challenge.Email = email;
        challenge.EmailVerified = identity.EmailVerified;
        challenge.DisplayName = CleanName(identity.Name);

        var existing = await _db.ExternalLogins.FirstOrDefaultAsync(
            login => login.Issuer == identity.Issuer && login.Subject == identity.Subject,
            cancellationToken);

        if (challenge.LinkUserId is Guid linkUserId)
        {
            await ResolveAuthenticatedLinkAsync(challenge, identity, email, existing, linkUserId, cancellationToken);
            return;
        }

        if (existing is not null)
        {
            Touch(existing, email, identity.EmailVerified);
            challenge.Outcome = SsoOutcomes.Authenticated;
            challenge.ResolvedUserId = existing.UserId;
            return;
        }

        if (email is null)
        {
            challenge.Outcome = SsoOutcomes.Error;
            challenge.ErrorCode = ErrorCodes.SsoEmailRequired;
            return;
        }

        var user = await _db.Users.FirstOrDefaultAsync(item => item.Email == email, cancellationToken);
        if (user is not null)
        {
            if (!identity.EmailVerified)
            {
                challenge.Outcome = SsoOutcomes.Error;
                challenge.ErrorCode = ErrorCodes.SsoEmailUnverified;
                return;
            }

            if (!PasswordHashes.IsSet(user.PasswordHash))
            {
                challenge.Outcome = SsoOutcomes.Error;
                challenge.ErrorCode = ErrorCodes.SsoLinkUnavailable;
                return;
            }

            challenge.Outcome = SsoOutcomes.LinkRequired;
            challenge.ResolvedUserId = user.Id;
            return;
        }

        if (!identity.EmailVerified)
        {
            challenge.Outcome = SsoOutcomes.Error;
            challenge.ErrorCode = ErrorCodes.SsoEmailUnverified;
            return;
        }

        if (!_configuration.AllowRegistration)
        {
            challenge.Outcome = SsoOutcomes.Error;
            challenge.ErrorCode = ErrorCodes.SsoRegistrationDisabled;
            return;
        }

        var now = _clock.UtcNow;
        var created = UserRegistration.CreateAccount(
            _db,
            AccountName(challenge.DisplayName, email),
            email,
            string.Empty,
            challenge.PreferredLanguage,
            challenge.PreferredCurrency,
            now);
        _db.ExternalLogins.Add(new ExternalLogin
        {
            Id = Guid.NewGuid(),
            UserId = created.Id,
            Provider = challenge.Provider,
            Issuer = identity.Issuer,
            Subject = identity.Subject,
            Email = email,
            EmailVerified = true,
            CreatedAt = now,
            LastUsedAt = now
        });
        challenge.Outcome = SsoOutcomes.Authenticated;
        challenge.ResolvedUserId = created.Id;
    }

    private async Task ResolveAuthenticatedLinkAsync(
        SsoChallenge challenge,
        VerifiedExternalIdentity identity,
        string? email,
        ExternalLogin? existing,
        Guid linkUserId,
        CancellationToken cancellationToken)
    {
        if (existing is not null)
        {
            challenge.Outcome = SsoOutcomes.Error;
            challenge.ErrorCode = existing.UserId == linkUserId
                ? ErrorCodes.SsoAlreadyLinked
                : ErrorCodes.SsoIdentityInUse;
            return;
        }

        var providerTaken = await _db.ExternalLogins.AnyAsync(
            login => login.UserId == linkUserId && login.Provider == challenge.Provider,
            cancellationToken);
        if (providerTaken)
        {
            challenge.Outcome = SsoOutcomes.Error;
            challenge.ErrorCode = ErrorCodes.SsoProviderAlreadyLinked;
            return;
        }

        var now = _clock.UtcNow;
        _db.ExternalLogins.Add(new ExternalLogin
        {
            Id = Guid.NewGuid(),
            UserId = linkUserId,
            Provider = challenge.Provider,
            Issuer = identity.Issuer,
            Subject = identity.Subject,
            Email = email,
            EmailVerified = identity.EmailVerified,
            CreatedAt = now,
            LastUsedAt = now
        });
        challenge.Outcome = SsoOutcomes.Linked;
        challenge.ResolvedUserId = linkUserId;
        challenge.Email = email;
    }

    private async Task<SsoChallenge> RecoverCreateConflictAsync(
        Guid challengeId,
        VerifiedExternalIdentity identity,
        string? email,
        CancellationToken cancellationToken)
    {
        _db.DetachAll();
        var reloaded = await _db.SsoChallenges.FirstAsync(item => item.Id == challengeId, cancellationToken);
        var taken = await _db.ExternalLogins.FirstOrDefaultAsync(
            login => login.Issuer == identity.Issuer && login.Subject == identity.Subject,
            cancellationToken);

        if (reloaded.LinkUserId is Guid linkUserId)
        {
            reloaded.Outcome = SsoOutcomes.Error;
            reloaded.ErrorCode = taken is not null && taken.UserId == linkUserId
                ? ErrorCodes.SsoAlreadyLinked
                : ErrorCodes.SsoIdentityInUse;
        }
        else if (taken is not null)
        {
            Touch(taken, email, identity.EmailVerified);
            reloaded.Outcome = SsoOutcomes.Authenticated;
            reloaded.ResolvedUserId = taken.UserId;
        }
        else if (!string.IsNullOrWhiteSpace(email))
        {
            var user = await _db.Users.FirstOrDefaultAsync(item => item.Email == email, cancellationToken);
            if (user is not null && identity.EmailVerified && PasswordHashes.IsSet(user.PasswordHash))
            {
                reloaded.Outcome = SsoOutcomes.LinkRequired;
                reloaded.ResolvedUserId = user.Id;
                reloaded.Email = email;
                reloaded.Issuer = identity.Issuer;
                reloaded.Subject = identity.Subject;
                reloaded.EmailVerified = true;
            }
            else if (user is not null)
            {
                reloaded.Outcome = SsoOutcomes.Error;
                reloaded.ErrorCode = ErrorCodes.SsoLinkUnavailable;
            }
            else
            {
                reloaded.Outcome = SsoOutcomes.Error;
                reloaded.ErrorCode = ErrorCodes.SsoInvalid;
            }
        }
        else
        {
            reloaded.Outcome = SsoOutcomes.Error;
            reloaded.ErrorCode = ErrorCodes.SsoInvalid;
        }

        reloaded.CodeVerifier = string.Empty;
        reloaded.Nonce = string.Empty;
        return reloaded;
    }

    private async Task<string?> IssueExchangeCodeAsync(SsoChallenge challenge, CancellationToken cancellationToken)
    {
        var exchangeCode = SecretTokens.Create();
        challenge.ExchangeCodeHash = SecretTokens.Sha256Hex(exchangeCode);
        challenge.ExchangeExpiresAt = _clock.UtcNow.Add(ExchangeLifetime);
        challenge.CodeVerifier = string.Empty;
        challenge.Nonce = string.Empty;
        await _db.SaveChangesAsync(cancellationToken);
        _logger.LogInformation("SSO callback {Outcome} for provider {Provider}", challenge.Outcome, challenge.Provider);
        return RedirectToApp(("code", exchangeCode));
    }

    private async Task<bool> CanUsePasswordAsync(Guid? userId, CancellationToken cancellationToken)
    {
        if (userId is null)
        {
            return false;
        }

        var hash = await _db.Users
            .Where(user => user.Id == userId)
            .Select(user => user.PasswordHash)
            .FirstOrDefaultAsync(cancellationToken);
        return PasswordHashes.IsSet(hash);
    }

    private async Task<string?> FailAsync(SsoChallenge challenge, string code, CancellationToken cancellationToken)
    {
        challenge.Outcome = SsoOutcomes.Error;
        challenge.ErrorCode = code;
        challenge.CodeVerifier = string.Empty;
        challenge.Nonce = string.Empty;
        await _db.SaveChangesAsync(cancellationToken);
        return RedirectToApp(("error", code));
    }

    private SsoResultDto AuthenticatedResult(User user, string? returnPath)
    {
        var (token, expiresIn) = _jwt.CreateToken(user.Id, user.Email, user.Name);
        return new SsoResultDto
        {
            Status = SsoStatuses.Authenticated,
            ReturnPath = returnPath,
            AccessToken = token,
            TokenType = "Bearer",
            ExpiresIn = expiresIn,
            User = _mapper.Map<UserProfileDto>(user)
        };
    }

    private string? RedirectToApp(params (string Key, string Value)[] pairs)
    {
        var callback = _configuration.AppCallbackUri;
        if (!_configuration.IsAppCallbackAllowed || string.IsNullOrWhiteSpace(callback))
        {
            return null;
        }

        var query = string.Join(
            "&",
            pairs.Select(pair => $"{Uri.EscapeDataString(pair.Key)}={Uri.EscapeDataString(pair.Value)}"));
        var separator = callback.Contains('?', StringComparison.Ordinal) ? "&" : "?";
        var location = callback + separator + query;
        if (!location.StartsWith(callback + separator, StringComparison.Ordinal))
        {
            return null;
        }

        return location;
    }

    private static string? MapProviderError(string? error)
    {
        if (string.IsNullOrWhiteSpace(error))
        {
            return null;
        }

        return error.Trim().ToLowerInvariant() switch
        {
            "access_denied" or "consent_required" or "cancelled" or "canceled" => ErrorCodes.SsoCancelled,
            "login_required" or "interaction_required" or "account_selection_required" => ErrorCodes.SsoExpired,
            _ => ErrorCodes.SsoProviderError
        };
    }

    private void Touch(ExternalLogin login, string? email, bool emailVerified)
    {
        login.LastUsedAt = _clock.UtcNow;
        if (!string.IsNullOrWhiteSpace(email))
        {
            login.Email = email;
        }

        login.EmailVerified = emailVerified;
    }

    private static string? NormalizeEmail(string? email)
    {
        if (string.IsNullOrWhiteSpace(email))
        {
            return null;
        }

        var value = email.Trim().ToLowerInvariant();
        var at = value.IndexOf('@');
        if (at <= 0 || at != value.LastIndexOf('@') || at == value.Length - 1 || value.Length > 256 || value.Contains(' ', StringComparison.Ordinal))
        {
            return null;
        }

        return value;
    }

    private static string? CleanName(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var cleaned = new string(value.Where(character => !char.IsControl(character)).ToArray()).Trim();
        if (cleaned.Length == 0)
        {
            return null;
        }

        return cleaned.Length > 120 ? cleaned[..120] : cleaned;
    }

    private static string AccountName(string? displayName, string email)
    {
        if (!string.IsNullOrWhiteSpace(displayName))
        {
            return displayName;
        }

        var at = email.IndexOf('@');
        var local = at > 0 ? email[..at] : "FinTrack";
        return local.Length > 120 ? local[..120] : local;
    }
}
