namespace FinTrack.Infrastructure.Auth.Sso;

public class SsoOptions
{
    public const string SectionName = "Sso";

    public string RedirectUri { get; set; } = string.Empty;
    public string AppCallbackUri { get; set; } = "fintrack://sso/callback";
    public string PostLogoutRedirectUri { get; set; } = "fintrack://sso/logout";
    public bool AllowRegistration { get; set; } = true;
    public GoogleSsoOptions Google { get; set; } = new();
    public MicrosoftSsoOptions Microsoft { get; set; } = new();
    public GenericOidcOptions Oidc { get; set; } = new();
}

public class GoogleSsoOptions
{
    public bool Enabled { get; set; }
    public string ClientId { get; set; } = string.Empty;
    public string ClientSecret { get; set; } = string.Empty;
    public string Issuer { get; set; } = "https://accounts.google.com";
}

public class MicrosoftSsoOptions
{
    public bool Enabled { get; set; }
    public string ClientId { get; set; } = string.Empty;
    public string ClientSecret { get; set; } = string.Empty;
    public string TenantId { get; set; } = "common";
}

public class GenericOidcOptions
{
    public bool Enabled { get; set; }
    public string ClientId { get; set; } = string.Empty;
    public string ClientSecret { get; set; } = string.Empty;
    public string Issuer { get; set; } = string.Empty;
    public string DisplayName { get; set; } = "Single sign-on";
}
