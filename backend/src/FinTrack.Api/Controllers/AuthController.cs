using FinTrack.Application.DTOs.Auth;
using FinTrack.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FinTrack.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [AllowAnonymous]
    [HttpPost("register")]
    [ProducesResponseType(
        typeof(MessageResponse),
        StatusCodes.Status202Accepted)]
    public async Task<ActionResult<MessageResponse>> Register(
        [FromBody] RegisterRequest request,
        CancellationToken cancellationToken)
    {
        var response = await _authService.RegisterAsync(
            request,
            cancellationToken);

        return Accepted(response);
    }

    [AllowAnonymous]
    [HttpPost("login")]
    [ProducesResponseType(
        typeof(AuthResponse),
        StatusCodes.Status200OK)]
    public async Task<ActionResult<AuthResponse>> Login(
        [FromBody] LoginRequest request,
        CancellationToken cancellationToken)
    {
        var response = await _authService.LoginAsync(
            request,
            cancellationToken);

        return Ok(response);
    }

    [AllowAnonymous]
    [HttpGet("verify-email")]
    [Produces("text/html")]
    public async Task<ContentResult> VerifyEmail(
        [FromQuery] string token,
        CancellationToken cancellationToken)
    {
        await _authService.VerifyEmailAsync(
            token,
            cancellationToken);

        const string html = """
        <!doctype html>
        <html lang="es">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>Correo verificado | FinTrack</title>
        </head>
        <body style="font-family: Arial, sans-serif; background: #f5f7fa; margin: 0; padding: 40px;">
            <main style="max-width: 520px; margin: auto; background: white; padding: 36px; border-radius: 16px; text-align: center;">
                <h1 style="color: #2457d6;">Correo verificado</h1>
                <p>Tu cuenta de FinTrack fue activada correctamente.</p>
                <p>Ya puedes volver a la aplicación e iniciar sesión.</p>
            </main>
        </body>
        </html>
        """;

        return Content(
            html,
            "text/html; charset=utf-8");
    }

    [AllowAnonymous]
    [HttpPost("resend-verification")]
    [ProducesResponseType(
        typeof(MessageResponse),
        StatusCodes.Status200OK)]
    public async Task<ActionResult<MessageResponse>> ResendVerification(
        [FromBody] EmailRequest request,
        CancellationToken cancellationToken)
    {
        await _authService.ResendVerificationEmailAsync(
            request,
            cancellationToken);

        return Ok(new MessageResponse
        {
            Message =
                "If the account exists and is pending verification, a new email was sent."
        });
    }
}