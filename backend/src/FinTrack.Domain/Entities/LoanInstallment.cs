using FinTrack.Domain.Enums;

namespace FinTrack.Domain.Entities;

public class LoanInstallment
{
    public Guid Id { get; set; }
    public Guid LoanId { get; set; }
    public int Number { get; set; }
    public DateTime DueDate { get; set; }
    public decimal PrincipalAmount { get; set; }
    public decimal InterestAmount { get; set; }
    public decimal FeeAmount { get; set; }
    public decimal TotalAmount { get; set; }
    public decimal PaidPrincipal { get; set; }
    public decimal PaidInterest { get; set; }
    public decimal PaidFees { get; set; }
    public decimal PaidTotal { get; set; }
    public decimal RemainingBalanceAfter { get; set; }
    public LoanInstallmentStatus Status { get; set; } = LoanInstallmentStatus.PENDING;
    public bool IsLocked { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public Loan Loan { get; set; } = null!;
    public ICollection<LoanPayment> Payments { get; set; } = new List<LoanPayment>();
}
