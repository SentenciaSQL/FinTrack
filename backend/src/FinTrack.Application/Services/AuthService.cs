using AutoMapper;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using FinTrack.Application.Common;
using FinTrack.Application.DTOs.Auth;
using FinTrack.Application.Interfaces;
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

    public AuthService(
        IFinTrackDbContext db,
        IPasswordHasher passwordHasher,
        IJwtTokenService jwt,
        IDateTimeProvider clock,
        IMapper mapper,
        IValidator<RegisterRequest> registerValidator,
        IValidator<LoginRequest> loginValidator)
    {
        _db = db;
        _passwordHasher = passwordHasher;
        _jwt = jwt;
        _clock = clock;
        _mapper = mapper;
        _registerValidator = registerValidator;
        _loginValidator = loginValidator;
    }

    public async Task<AuthResponse> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default)
    {
        await _registerValidator.ValidateAndThrowAppAsync(request, cancellationToken);

        var email = request.Email.Trim().ToLowerInvariant();
        var exists = await _db.Users.AnyAsync(u => u.Email == email, cancellationToken);
        if (exists)
        {
            throw new ConflictException(ErrorCodes.EmailAlreadyExists, "A user with this email already exists");
        }

        var now = _clock.UtcNow;
        var user = UserRegistration.CreateAccount(
            _db,
            request.Name.Trim(),
            email,
            _passwordHasher.Hash(request.Password),
            string.IsNullOrWhiteSpace(request.PreferredLanguage) ? "es" : request.PreferredLanguage,
            string.IsNullOrWhiteSpace(request.PreferredCurrency) ? "DOP" : request.PreferredCurrency,
            now);

        await _db.SaveChangesAsync(cancellationToken);
        return CreateAuthResponse(user);
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default)
    {
        await _loginValidator.ValidateAndThrowAppAsync(request, cancellationToken);

        var email = request.Email.Trim().ToLowerInvariant();
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email, cancellationToken);
        if (user is null || !PasswordHashes.IsSet(user.PasswordHash) || !_passwordHasher.Verify(request.Password, user.PasswordHash))
        {
            throw new UnauthorizedException("Invalid email or password");
        }

        return CreateAuthResponse(user);
    }

    private AuthResponse CreateAuthResponse(User user)
    {
        var (token, expiresIn) = _jwt.CreateToken(user.Id, user.Email, user.Name);
        return new AuthResponse
        {
            AccessToken = token,
            TokenType = "Bearer",
            ExpiresIn = expiresIn,
            User = _mapper.Map<UserProfileDto>(user)
        };
    }
}
