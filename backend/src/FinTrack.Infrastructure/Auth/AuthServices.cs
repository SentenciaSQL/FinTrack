using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using FinTrack.Application.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace FinTrack.Infrastructure.Auth;

public class JwtTokenService : IJwtTokenService
{
    private readonly IConfiguration _configuration;

    public JwtTokenService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public (string Token, int ExpiresIn) CreateToken(Guid userId, string email, string name)
    {
        var secret = _configuration["Jwt:Secret"] ?? throw new InvalidOperationException("JWT secret is not configured");
        var issuer = _configuration["Jwt:Issuer"] ?? "FinTrack";
        var audience = _configuration["Jwt:Audience"] ?? "FinTrackMobile";
        var minutes = int.TryParse(_configuration["Jwt:ExpirationMinutes"], out var value) ? value : 1440;
        var expires = DateTime.UtcNow.AddMinutes(minutes);

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()),
            new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, email),
            new Claim(ClaimTypes.Email, email),
            new Claim(JwtRegisteredClaimNames.Name, name),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(issuer, audience, claims, expires: expires, signingCredentials: credentials);

        return (new JwtSecurityTokenHandler().WriteToken(token), minutes * 60);
    }
}

public class BcryptPasswordHasher : IPasswordHasher
{
    public string Hash(string password) => BCrypt.Net.BCrypt.HashPassword(password, workFactor: 12);

    public bool Verify(string password, string hash) => BCrypt.Net.BCrypt.Verify(password, hash);
}

public class DateTimeProvider : IDateTimeProvider
{
    public DateTime UtcNow => DateTime.UtcNow;
}
