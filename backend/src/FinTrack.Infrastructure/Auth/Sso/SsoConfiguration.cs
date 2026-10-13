using FinTrack.Application.Interfaces;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;

namespace FinTrack.Infrastructure.Auth.Sso;

public class SsoConfiguration : ISsoConfiguration
{
    private readonly SsoOptions _options;
    private readonly bool _development;

    public SsoConfiguration(IOptions<SsoOptions> options, IHostEnvironment environment)
    {
        _options = options.Value;
        _development = environment.IsDevelopment();
    }

    public bool AllowRegistration => _options.AllowRegistration;
    public string AppCallbackUri => _options.AppCallbackUri?.Trim() ?? string.Empty;
    public string PostLogoutRedirectUri => _options.PostLogoutRedirectUri?.Trim() ?? string.Empty;
    public bool IsAppCallbackAllowed => IsAllowedAbsoluteUri(AppCallbackUri, allowHttpLoopback: _development);

    public static bool IsAllowedAbsoluteUri(string? value, bool allowHttpLoopback)
    {
        if (string.IsNullOrWhiteSpace(value) || !Uri.TryCreate(value, UriKind.Absolute, out var uri))
        {
            return false;
        }

        if (!string.IsNullOrEmpty(uri.UserInfo))
        {
            return false;
        }

        if (uri.Scheme is "javascript" or "data" or "file" or "vbscript")
        {
            return false;
        }

        if (uri.Scheme == Uri.UriSchemeHttps)
        {
            return true;
        }

        if (uri.Scheme == Uri.UriSchemeHttp)
        {
            return allowHttpLoopback && uri.IsLoopback;
        }

        return !string.IsNullOrEmpty(uri.Host);
    }
}
