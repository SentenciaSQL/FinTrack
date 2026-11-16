using FinTrack.Domain.Enums;

namespace FinTrack.Domain.Entities;

public class Loan
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Creditor { get; set; } = string.Empty;
    public LoanType LoanType { get; set; }
    public decimal OriginalPrincipal { get; set; }
    public string Currency { get; set; } = "DOP";
    public decimal AnnualInterestRate { get; set; }
    public DateTime DisbursementDate { get; set; }
    public DateTime FirstInstallmentDate { get; set; }
    public int TermMonths { get; set; }
    public LoanPaymentFrequency PaymentFrequency { get; set; }
    public AmortizationType AmortizationType { get; set; }
    public string? AssociatedAccountLabel { get; set; }
    public int? PreferredPaymentDay { get; set; }
    public decimal AdditionalFees { get; set; }
    public string? Notes { get; set; }

    public decimal CurrentBalance { get; set; }
    public int RemainingInstallments { get; set; }
    public decimal AccruedInterestPending { get; set; }
    public DateTime? NextPaymentDate { get; set; }
    public decimal PeriodicPayment { get; set; }
    public LoanStatus Status { get; set; } = LoanStatus.ACTIVE;

    public decimal EarlyPaymentPenaltyRate { get; set; }
    public decimal EarlyPaymentPenaltyFixed { get; set; }
    public string ReminderDaysCsv { get; set; } = "7,3,1,0";
    public bool RemindOnOverdue { get; set; } = true;
    public Guid? DefaultCategoryId { get; set; }
    public bool IsEstimate { get; set; }

    public decimal TotalInterestPaid { get; set; }
    public decimal TotalPrincipalPaid { get; set; }
    public decimal TotalExtraPrincipalPaid { get; set; }
    public decimal TotalInterestSaved { get; set; }
    public decimal TotalFeesPaid { get; set; }
    public decimal TotalPenaltiesPaid { get; set; }

    public Guid UserId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public User User { get; set; } = null!;
    public Category? DefaultCategory { get; set; }
    public ICollection<LoanInstallment> Installments { get; set; } = new List<LoanInstallment>();
    public ICollection<LoanPayment> Payments { get; set; } = new List<LoanPayment>();
    public ICollection<LoanChangeLog> ChangeLogs { get; set; } = new List<LoanChangeLog>();
}
