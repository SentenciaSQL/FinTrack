namespace FinTrack.Domain.Entities;

/// <summary>
/// A verified identity-provider account linked to a FinTrack user.
/// Users are matched by issuer and subject, never by email alone.
/// </summary>
public class ExternalLogin
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Provider { get; set; } = string.Empty;
    public string Issuer { get; set; } = string.Empty;
    public string Subject { get; set; } = string.Empty;
    public string? Email { get; set; }
    public bool EmailVerified { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime LastUsedAt { get; set; }

    public User User { get; set; } = null!;
}
