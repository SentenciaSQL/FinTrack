using FinTrack.Application.DTOs.Auth;
using FinTrack.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FinTrack.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/users")]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly ISsoAuthService _ssoAuthService;

    public UsersController(IUserService userService, ISsoAuthService ssoAuthService)
    {
        _userService = userService;
        _ssoAuthService = ssoAuthService;
    }

    [HttpGet("me")]
    [ProducesResponseType(typeof(UserProfileDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<UserProfileDto>> GetMe(CancellationToken cancellationToken)
    {
        return Ok(await _userService.GetCurrentAsync(cancellationToken));
    }

    [HttpPut("me")]
    [ProducesResponseType(typeof(UserProfileDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<UserProfileDto>> UpdateMe([FromBody] UpdateProfileRequest request, CancellationToken cancellationToken)
    {
        return Ok(await _userService.UpdateCurrentAsync(request, cancellationToken));
    }

    [HttpPut("me/password")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request, CancellationToken cancellationToken)
    {
        await _userService.ChangePasswordAsync(request, cancellationToken);
        return NoContent();
    }

    [HttpPost("me/password")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> SetInitialPassword([FromBody] SetInitialPasswordRequest request, CancellationToken cancellationToken)
    {
        await _userService.SetInitialPasswordAsync(request, cancellationToken);
        return NoContent();
    }

    [HttpGet("me/auth-methods")]
    [ProducesResponseType(typeof(AuthMethodsDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<AuthMethodsDto>> AuthMethods(CancellationToken cancellationToken)
    {
        return Ok(await _ssoAuthService.GetMethodsAsync(cancellationToken));
    }

    [HttpDelete("me/auth-methods/{provider}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Unlink(string provider, CancellationToken cancellationToken)
    {
        await _ssoAuthService.UnlinkAsync(provider, cancellationToken);
        return NoContent();
    }
}
