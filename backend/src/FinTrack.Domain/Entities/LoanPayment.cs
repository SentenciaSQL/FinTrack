using FinTrack.Domain.Enums;

namespace FinTrack.Domain.Entities;

public class LoanPayment
{
    public Guid Id { get; set; }
    public Guid LoanId { get; set; }
    public Guid? InstallmentId { get; set; }
    public LoanPaymentKind Kind { get; set; }
    public decimal Amount { get; set; }
    public decimal PrincipalPortion { get; set; }
    public decimal InterestPortion { get; set; }
    public decimal FeePortion { get; set; }
    public decimal PenaltyPortion { get; set; }
    public DateTime Date { get; set; }
    public PaymentMethod PaymentMethod { get; set; }
    public Guid? CategoryId { get; set; }
    public Guid? TransactionId { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; }

    public Loan Loan { get; set; } = null!;
    public LoanInstallment? Installment { get; set; }
    public Category? Category { get; set; }
    public Transaction? Transaction { get; set; }
}
