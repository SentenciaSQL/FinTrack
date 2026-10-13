namespace FinTrack.Application.DTOs.Auth;

public class SsoProviderDto
{
    public string Id { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
}

public class SsoStartRequest
{
    public string Provider { get; set; } = string.Empty;
    public string Intent { get; set; } = "sign_in";
    public string? ReturnPath { get; set; }
    public string? PreferredLanguage { get; set; }
    public string? PreferredCurrency { get; set; }
}

public class SsoStartResponse
{
    public string AuthorizationUrl { get; set; } = string.Empty;
    public string State { get; set; } = string.Empty;
}

public class SsoExchangeRequest
{
    public string Code { get; set; } = string.Empty;
    public string State { get; set; } = string.Empty;
}

public class SsoLinkRequest
{
    public string LinkToken { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

public class SsoResultDto
{
    public string Status { get; set; } = string.Empty;
    public string? ReturnPath { get; set; }
    public string? AccessToken { get; set; }
    public string? TokenType { get; set; }
    public int? ExpiresIn { get; set; }
    public UserProfileDto? User { get; set; }
    public string? LinkToken { get; set; }
    public string? Email { get; set; }
    public string? Provider { get; set; }
    public string? ProviderDisplayName { get; set; }
    public bool? CanUsePassword { get; set; }
}

public class LinkedAuthMethodDto
{
    public string Provider { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string? Email { get; set; }
    public DateTime LinkedAt { get; set; }
}

public class AuthMethodsDto
{
    public bool HasPassword { get; set; }
    public IReadOnlyList<LinkedAuthMethodDto> Methods { get; set; } = Array.Empty<LinkedAuthMethodDto>();
    public IReadOnlyList<SsoProviderDto> AvailableProviders { get; set; } = Array.Empty<SsoProviderDto>();
}

public class SsoLogoutResponse
{
    public string? Url { get; set; }
}
