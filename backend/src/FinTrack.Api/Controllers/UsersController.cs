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

    public UsersController(IUserService userService)
    {
        _userService = userService;
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
}
