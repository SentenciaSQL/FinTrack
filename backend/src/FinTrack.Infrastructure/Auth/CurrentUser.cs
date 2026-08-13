using System.Security.Claims;
using FinTrack.Application.Common;
using FinTrack.Application.Interfaces;
using Microsoft.AspNetCore.Http;

namespace FinTrack.Infrastructure.Auth;

public class CurrentUser : ICurrentUser
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public CurrentUser(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public bool IsAuthenticated =>
        _httpContextAccessor.HttpContext?.User.Identity?.IsAuthenticated == true;

    public Guid UserId
    {
        get
        {
            var principal = _httpContextAccessor.HttpContext?.User
                            ?? throw new UnauthorizedException("Authentication is required");

            var value = principal.FindFirstValue(ClaimTypes.NameIdentifier)
                        ?? principal.FindFirstValue("sub");

            if (!Guid.TryParse(value, out var userId))
            {
                throw new UnauthorizedException("Invalid authentication token");
            }

            return userId;
        }
    }
}
