namespace FinTrack.Domain.Entities;

/// <summary>
/// Short-lived authorization-code transaction. Holds the PKCE verifier, nonce,
/// and one-time codes until the browser round trip finishes.
/// </summary>
public class SsoChallenge
{
    public Guid Id { get; set; }
    public string StateHash { get; set; } = string.Empty;
    public string Nonce { get; set; } = string.Empty;
    public string CodeVerifier { get; set; } = string.Empty;
    public string Provider { get; set; } = string.Empty;
    public string Intent { get; set; } = "sign_in";
    public string? ReturnPath { get; set; }
    public Guid? LinkUserId { get; set; }
    public string PreferredLanguage { get; set; } = "es";
    public string PreferredCurrency { get; set; } = "DOP";
    public DateTime CreatedAt { get; set; }
    public DateTime ExpiresAt { get; set; }
    public DateTime? AuthorizedAt { get; set; }
    public string? ExchangeCodeHash { get; set; }
    public DateTime? ExchangeExpiresAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public string? LinkTokenHash { get; set; }
    public DateTime? LinkConsumedAt { get; set; }
    public int LinkAttempts { get; set; }
    public string Outcome { get; set; } = "pending";
    public string? ErrorCode { get; set; }
    public Guid? ResolvedUserId { get; set; }
    public string? Issuer { get; set; }
    public string? Subject { get; set; }
    public string? Email { get; set; }
    public bool EmailVerified { get; set; }
    public string? DisplayName { get; set; }
}
