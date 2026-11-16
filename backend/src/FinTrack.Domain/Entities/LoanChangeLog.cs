namespace FinTrack.Domain.Entities;

public class LoanChangeLog
{
    public Guid Id { get; set; }
    public Guid LoanId { get; set; }
    public string Description { get; set; } = string.Empty;
    public string? Details { get; set; }
    public DateTime ChangedAt { get; set; }

    public Loan Loan { get; set; } = null!;
}
