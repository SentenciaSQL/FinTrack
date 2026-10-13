using FinTrack.Application.DTOs.Auth;
using FinTrack.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace FinTrack.Api.Controllers;

[ApiController]
[EnableRateLimiting("auth")]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private const string BrowserFallbackHtml =
        "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\"><title>FinTrack</title></head><body><p>Sign-in could not be completed. Close this window and try again in the FinTrack app.</p></body></html>";

    private readonly IAuthService _authService;
    private readonly ISsoAuthService _ssoAuthService;
    private readonly ICurrentUser _currentUser;
    private readonly ISsoConfiguration _ssoConfiguration;

    public AuthController(
        IAuthService authService,
        ISsoAuthService ssoAuthService,
        ICurrentUser currentUser,
        ISsoConfiguration ssoConfiguration)
    {
        _authService = authService;
        _ssoAuthService = ssoAuthService;
        _currentUser = currentUser;
        _ssoConfiguration = ssoConfiguration;
    }

    [AllowAnonymous]
    [HttpPost("register")]
    [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<AuthResponse>> Register([FromBody] RegisterRequest request, CancellationToken cancellationToken)
    {
        return Ok(await _authService.RegisterAsync(request, cancellationToken));
    }

    [AllowAnonymous]
    [HttpPost("login")]
    [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<AuthResponse>> Login([FromBody] LoginRequest request, CancellationToken cancellationToken)
    {
        return Ok(await _authService.LoginAsync(request, cancellationToken));
    }

    [AllowAnonymous]
    [HttpGet("sso/providers")]
    [ProducesResponseType(typeof(IReadOnlyList<SsoProviderDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<SsoProviderDto>>> Providers(CancellationToken cancellationToken)
    {
        return Ok(await _ssoAuthService.GetProvidersAsync(cancellationToken));
    }

    [AllowAnonymous]
    [HttpPost("sso/start")]
    [ProducesResponseType(typeof(SsoStartResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<SsoStartResponse>> Start([FromBody] SsoStartRequest request, CancellationToken cancellationToken)
    {
        Guid? userId = _currentUser.IsAuthenticated ? _currentUser.UserId : null;
        return Ok(await _ssoAuthService.StartAsync(request, userId, cancellationToken));
    }

    [AllowAnonymous]
    [HttpGet("sso/callback")]
    public async Task<IActionResult> Callback(
        [FromQuery] string? code,
        [FromQuery] string? state,
        [FromQuery] string? error,
        CancellationToken cancellationToken)
    {
        Response.Headers.CacheControl = "no-store";
        Response.Headers.Pragma = "no-cache";
        Response.Headers["Referrer-Policy"] = "no-referrer";
        var location = await _ssoAuthService.CompleteCallbackAsync(code, state, error, cancellationToken);
        var callback = _ssoConfiguration.AppCallbackUri;
        if (string.IsNullOrWhiteSpace(location)
            || string.IsNullOrWhiteSpace(callback)
            || !location.StartsWith(callback + (callback.Contains('?') ? "&" : "?"), StringComparison.Ordinal))
        {
            return Content(BrowserFallbackHtml, "text/html");
        }

        return Redirect(location);
    }

    [AllowAnonymous]
    [HttpPost("sso/exchange")]
    [ProducesResponseType(typeof(SsoResultDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<SsoResultDto>> Exchange([FromBody] SsoExchangeRequest request, CancellationToken cancellationToken)
    {
        Response.Headers.CacheControl = "no-store";
        return Ok(await _ssoAuthService.ExchangeAsync(request, cancellationToken));
    }

    [AllowAnonymous]
    [HttpPost("sso/link")]
    [ProducesResponseType(typeof(SsoResultDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<SsoResultDto>> Link([FromBody] SsoLinkRequest request, CancellationToken cancellationToken)
    {
        Response.Headers.CacheControl = "no-store";
        return Ok(await _ssoAuthService.LinkWithPasswordAsync(request, cancellationToken));
    }

    [Authorize]
    [HttpGet("sso/logout")]
    [ProducesResponseType(typeof(SsoLogoutResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<SsoLogoutResponse>> Logout(CancellationToken cancellationToken)
    {
        return Ok(await _ssoAuthService.CreateLogoutAsync(cancellationToken));
    }
}
