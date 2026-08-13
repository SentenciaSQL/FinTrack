using FinTrack.Application.DTOs.Auth;

namespace FinTrack.Application.Interfaces;

public interface IAuthService
{
    Task<AuthResponse> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default);
    Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default);
}

public interface IUserService
{
    Task<UserProfileDto> GetCurrentAsync(CancellationToken cancellationToken = default);
    Task<UserProfileDto> UpdateCurrentAsync(UpdateProfileRequest request, CancellationToken cancellationToken = default);
    Task ChangePasswordAsync(ChangePasswordRequest request, CancellationToken cancellationToken = default);
}

public interface IJwtTokenService
{
    (string Token, int ExpiresIn) CreateToken(Guid userId, string email, string name);
}

public interface IPasswordHasher
{
    string Hash(string password);
    bool Verify(string password, string hash);
}

public interface ICurrentUser
{
    Guid UserId { get; }
    bool IsAuthenticated { get; }
}

public interface IDateTimeProvider
{
    DateTime UtcNow { get; }
}
