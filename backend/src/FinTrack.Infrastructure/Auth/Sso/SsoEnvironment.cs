namespace FinTrack.Infrastructure.Auth.Sso;

public static class SsoEnvironment
{
    public static void Apply(SsoOptions options)
    {
        options.RedirectUri = Prefer(Environment.GetEnvironmentVariable("SSO_REDIRECT_URI"), Environment.GetEnvironmentVariable("OIDC_REDIRECT_URI"), options.RedirectUri);
        options.AppCallbackUri = Prefer(Environment.GetEnvironmentVariable("SSO_APP_CALLBACK_URI"), options.AppCallbackUri);
        options.PostLogoutRedirectUri = Prefer(Environment.GetEnvironmentVariable("SSO_POST_LOGOUT_REDIRECT_URI"), options.PostLogoutRedirectUri);
        if (bool.TryParse(Environment.GetEnvironmentVariable("SSO_ALLOW_REGISTRATION"), out var allowRegistration))
        {
            options.AllowRegistration = allowRegistration;
        }

        options.Google.ClientId = Prefer(Environment.GetEnvironmentVariable("GOOGLE_CLIENT_ID"), options.Google.ClientId);
        options.Google.ClientSecret = Prefer(Environment.GetEnvironmentVariable("GOOGLE_CLIENT_SECRET"), options.Google.ClientSecret);
        options.Google.Issuer = Prefer(Environment.GetEnvironmentVariable("GOOGLE_ISSUER"), options.Google.Issuer);
        if (bool.TryParse(Environment.GetEnvironmentVariable("SSO_GOOGLE_ENABLED"), out var googleEnabled))
        {
            options.Google.Enabled = googleEnabled;
        }

        options.Microsoft.ClientId = Prefer(Environment.GetEnvironmentVariable("MICROSOFT_CLIENT_ID"), options.Microsoft.ClientId);
        options.Microsoft.ClientSecret = Prefer(Environment.GetEnvironmentVariable("MICROSOFT_CLIENT_SECRET"), options.Microsoft.ClientSecret);
        options.Microsoft.TenantId = Prefer(Environment.GetEnvironmentVariable("MICROSOFT_TENANT_ID"), options.Microsoft.TenantId);
        if (bool.TryParse(Environment.GetEnvironmentVariable("SSO_MICROSOFT_ENABLED"), out var microsoftEnabled))
        {
            options.Microsoft.Enabled = microsoftEnabled;
        }

        options.Oidc.ClientId = Prefer(Environment.GetEnvironmentVariable("OIDC_CLIENT_ID"), options.Oidc.ClientId);
        options.Oidc.ClientSecret = Prefer(Environment.GetEnvironmentVariable("OIDC_CLIENT_SECRET"), options.Oidc.ClientSecret);
        options.Oidc.Issuer = Prefer(Environment.GetEnvironmentVariable("OIDC_ISSUER_URI"), options.Oidc.Issuer);
        options.Oidc.DisplayName = Prefer(Environment.GetEnvironmentVariable("OIDC_DISPLAY_NAME"), options.Oidc.DisplayName);
        if (bool.TryParse(Environment.GetEnvironmentVariable("SSO_OIDC_ENABLED"), out var oidcEnabled))
        {
            options.Oidc.Enabled = oidcEnabled;
        }
    }

    private static string Prefer(params string?[] values)
    {
        foreach (var value in values)
        {
            if (!string.IsNullOrWhiteSpace(value))
            {
                return value.Trim();
            }
        }

        return string.Empty;
    }
}
