using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Encodings.Web;
using FinTrack.Application.Interfaces;
using Microsoft.Extensions.Configuration;

namespace FinTrack.Infrastructure.Email;

public sealed class ResendEmailService : IEmailService
{
    private readonly HttpClient _httpClient;
    private readonly string _apiKey;
    private readonly string _from;
    private readonly string _publicBaseUrl;

    public ResendEmailService(
        HttpClient httpClient,
        IConfiguration configuration)
    {
        _httpClient = httpClient;

        _apiKey =
            configuration["Resend:ApiKey"] ??
            string.Empty;

        _from =
            configuration["Resend:From"] ??
            "FinTrack <onboarding@resend.dev>";

        _publicBaseUrl =
            (configuration["App:PublicBaseUrl"] ??
             "http://localhost:8080")
            .TrimEnd('/');
    }

    public async Task SendVerificationEmailAsync(
        string recipientEmail,
        string recipientName,
        string verificationToken,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(_apiKey))
        {
            throw new InvalidOperationException(
                "Resend:ApiKey is not configured");
        }

        var verificationUrl =
            $"{_publicBaseUrl}/api/auth/verify-email" +
            $"?token={Uri.EscapeDataString(verificationToken)}";

        using var request = new HttpRequestMessage(
            HttpMethod.Post,
            "emails");

        request.Headers.Authorization =
            new AuthenticationHeaderValue(
                "Bearer",
                _apiKey);

        request.Content = JsonContent.Create(new
        {
            from = _from,
            to = new[]
            {
                recipientEmail
            },
            subject = "Confirma tu correo en FinTrack",
            html = BuildHtml(
                recipientName,
                verificationUrl)
        });

        using var response =
            await _httpClient.SendAsync(
                request,
                cancellationToken);

        response.EnsureSuccessStatusCode();
    }

    private static string BuildHtml(
        string name,
        string verificationUrl)
    {
        var safeName =
            HtmlEncoder.Default.Encode(name);

        var safeUrl =
            HtmlEncoder.Default.Encode(verificationUrl);

        return $$"""
        <!doctype html>
        <html lang="es">
        <body style="font-family: Arial, sans-serif; background: #f5f7fa; padding: 32px;">
            <div style="max-width: 560px; margin: auto; background: #ffffff; padding: 32px; border-radius: 16px;">
                <h1 style="color: #2457d6;">
                    Confirma tu correo
                </h1>

                <p>Hola {{safeName}},</p>

                <p>
                    Confirma tu dirección de correo para activar
                    tu cuenta de FinTrack.
                </p>

                <p style="margin: 32px 0;">
                    <a
                        href="{{safeUrl}}"
                        style="background: #2457d6; color: #ffffff; text-decoration: none; padding: 14px 22px; border-radius: 8px;">
                        Verificar mi correo
                    </a>
                </p>

                <p>
                    Este enlace vence en 24 horas.
                    Si no creaste esta cuenta, puedes ignorar este mensaje.
                </p>
            </div>
        </body>
        </html>
        """;
    }
}