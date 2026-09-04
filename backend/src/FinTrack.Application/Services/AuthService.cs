using System.Security.Cryptography;
using System.Text;
using AutoMapper;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using FinTrack.Application.Common;
using FinTrack.Application.DTOs.Auth;
using FinTrack.Application.Interfaces;
using FinTrack.Domain.Common;
using FinTrack.Domain.Entities;

namespace FinTrack.Application.Services;

public class AuthService : IAuthService
{
    private readonly IFinTrackDbContext _db;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IJwtTokenService _jwt;
    private readonly IDateTimeProvider _clock;
    private readonly IMapper _mapper;
    private readonly IValidator<RegisterRequest> _registerValidator;
    private readonly IValidator<LoginRequest> _loginValidator;
    private readonly IEmailService _emailService;

    public AuthService(
        IFinTrackDbContext db,
        IPasswordHasher passwordHasher,
        IJwtTokenService jwt,
        IDateTimeProvider clock,
        IMapper mapper,
        IValidator<RegisterRequest> registerValidator,
        IValidator<LoginRequest> loginValidator,
        IEmailService emailService)
    {
        _db = db;
        _passwordHasher = passwordHasher;
        _jwt = jwt;
        _clock = clock;
        _mapper = mapper;
        _registerValidator = registerValidator;
        _loginValidator = loginValidator;
        _emailService = emailService;
    }

    public async Task<MessageResponse> RegisterAsync(
        RegisterRequest request,
        CancellationToken cancellationToken = default)
    {
        await _registerValidator.ValidateAndThrowAppAsync(
            request,
            cancellationToken);

        var email = request.Email.Trim().ToLowerInvariant();

        var existingUser = await _db.Users.FirstOrDefaultAsync(
            user => user.Email == email,
            cancellationToken);

        if (existingUser?.IsEmailVerified == true)
        {
            throw new ConflictException(
                ErrorCodes.EmailAlreadyExists,
                "A user with this email already exists");
        }

        if (existingUser is not null)
        {
            var newToken = CreateVerificationToken();

            existingUser.EmailVerificationTokenHash = HashToken(newToken);
            existingUser.EmailVerificationTokenExpiresAt =
                _clock.UtcNow.AddHours(24);
            existingUser.UpdatedAt = _clock.UtcNow;

            await _db.SaveChangesAsync(cancellationToken);

            await _emailService.SendVerificationEmailAsync(
                existingUser.Email,
                existingUser.Name,
                newToken,
                cancellationToken);

            return new MessageResponse
            {
                Message =
                    "Registration successful. Check your email to verify your account."
            };
        }

        var now = _clock.UtcNow;
        var verificationToken = CreateVerificationToken();

        var user = new User
        {
            Id = Guid.NewGuid(),
            Name = request.Name.Trim(),
            Email = email,
            PasswordHash = _passwordHasher.Hash(request.Password),
            IsEmailVerified = false,
            EmailVerificationTokenHash = HashToken(verificationToken),
            EmailVerificationTokenExpiresAt = now.AddHours(24),
            PreferredLanguage =
                string.IsNullOrWhiteSpace(request.PreferredLanguage)
                    ? "es"
                    : request.PreferredLanguage,
            PreferredCurrency =
                string.IsNullOrWhiteSpace(request.PreferredCurrency)
                    ? "DOP"
                    : request.PreferredCurrency,
            CreatedAt = now,
            UpdatedAt = now
        };

        _db.Users.Add(user);

        foreach (var (code, type, icon) in DefaultCategories.All)
        {
            _db.Categories.Add(new Category
            {
                Id = Guid.NewGuid(),
                Name = code,
                Icon = icon,
                Type = type,
                UserId = user.Id,
                IsDefault = true,
                CreatedAt = now
            });
        }

        await _db.SaveChangesAsync(cancellationToken);

        await _emailService.SendVerificationEmailAsync(
            user.Email,
            user.Name,
            verificationToken,
            cancellationToken);

        return new MessageResponse
        {
            Message =
                "Registration successful. Check your email to verify your account."
        };
    }

    public async Task<AuthResponse> LoginAsync(
        LoginRequest request,
        CancellationToken cancellationToken = default)
    {
        await _loginValidator.ValidateAndThrowAppAsync(
            request,
            cancellationToken);

        var email = request.Email.Trim().ToLowerInvariant();

        var user = await _db.Users.FirstOrDefaultAsync(
            item => item.Email == email,
            cancellationToken);

        if (user is null ||
            !_passwordHasher.Verify(request.Password, user.PasswordHash))
        {
            throw new UnauthorizedException(
                "Invalid email or password");
        }

        if (!user.IsEmailVerified)
        {
            throw new AppException(
                ErrorCodes.EmailNotVerified,
                "Verify your email before signing in",
                403);
        }

        return CreateAuthResponse(user);
    }

    public async Task VerifyEmailAsync(
        string token,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            throw new AppException(
                ErrorCodes.InvalidVerificationToken,
                "The verification link is invalid or expired",
                400);
        }

        var tokenHash = HashToken(token);
        var now = _clock.UtcNow;

        var user = await _db.Users.FirstOrDefaultAsync(
            item =>
                item.EmailVerificationTokenHash == tokenHash &&
                !item.IsEmailVerified &&
                item.EmailVerificationTokenExpiresAt.HasValue &&
                item.EmailVerificationTokenExpiresAt.Value > now,
            cancellationToken);

        if (user is null)
        {
            throw new AppException(
                ErrorCodes.InvalidVerificationToken,
                "The verification link is invalid or expired",
                400);
        }

        user.IsEmailVerified = true;
        user.EmailVerificationTokenHash = null;
        user.EmailVerificationTokenExpiresAt = null;
        user.UpdatedAt = now;

        await _db.SaveChangesAsync(cancellationToken);
    }

    public async Task ResendVerificationEmailAsync(
        EmailRequest request,
        CancellationToken cancellationToken = default)
    {
        var email = request.Email.Trim().ToLowerInvariant();

        var user = await _db.Users.FirstOrDefaultAsync(
            item => item.Email == email,
            cancellationToken);

        if (user is null || user.IsEmailVerified)
        {
            return;
        }

        var verificationToken = CreateVerificationToken();

        user.EmailVerificationTokenHash =
            HashToken(verificationToken);

        user.EmailVerificationTokenExpiresAt =
            _clock.UtcNow.AddHours(24);

        user.UpdatedAt = _clock.UtcNow;

        await _db.SaveChangesAsync(cancellationToken);

        await _emailService.SendVerificationEmailAsync(
            user.Email,
            user.Name,
            verificationToken,
            cancellationToken);
    }

    private static string CreateVerificationToken()
    {
        var tokenBytes = RandomNumberGenerator.GetBytes(32);

        return Convert.ToHexString(tokenBytes);
    }

    private static string HashToken(string token)
    {
        var tokenBytes = Encoding.UTF8.GetBytes(token);
        var hashBytes = SHA256.HashData(tokenBytes);

        return Convert.ToHexString(hashBytes);
    }

    private AuthResponse CreateAuthResponse(User user)
    {
        var (token, expiresIn) = _jwt.CreateToken(
            user.Id,
            user.Email,
            user.Name);

        return new AuthResponse
        {
            AccessToken = token,
            TokenType = "Bearer",
            ExpiresIn = expiresIn,
            User = _mapper.Map<UserProfileDto>(user)
        };
    }
}