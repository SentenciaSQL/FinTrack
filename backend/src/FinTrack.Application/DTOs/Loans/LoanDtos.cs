using FinTrack.Domain.Enums;

namespace FinTrack.Application.DTOs.Loans;

public class LoanDto
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
    public LoanStatus Status { get; set; }
    public decimal EarlyPaymentPenaltyRate { get; set; }
    public decimal EarlyPaymentPenaltyFixed { get; set; }
    public IReadOnlyList<int> ReminderDays { get; set; } = Array.Empty<int>();
    public bool RemindOnOverdue { get; set; }
    public Guid? DefaultCategoryId { get; set; }
    public string? DefaultCategoryName { get; set; }
    public bool IsEstimate { get; set; }
    public decimal TotalInterestPaid { get; set; }
    public decimal TotalPrincipalPaid { get; set; }
    public decimal TotalExtraPrincipalPaid { get; set; }
    public decimal TotalInterestSaved { get; set; }
    public decimal TotalFeesPaid { get; set; }
    public decimal TotalPenaltiesPaid { get; set; }
    public decimal PaidOffPercentage { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class CreateLoanRequest
{
    public string Name { get; set; } = string.Empty;
    public string Creditor { get; set; } = string.Empty;
    public LoanType LoanType { get; set; } = LoanType.PERSONAL;
    public decimal OriginalPrincipal { get; set; }
    public string Currency { get; set; } = "DOP";
    public decimal AnnualInterestRate { get; set; }
    public DateTime DisbursementDate { get; set; }
    public DateTime FirstInstallmentDate { get; set; }
    public int TermMonths { get; set; }
    public LoanPaymentFrequency PaymentFrequency { get; set; } = LoanPaymentFrequency.MONTHLY;
    public AmortizationType AmortizationType { get; set; } = AmortizationType.FRENCH;
    public string? AssociatedAccountLabel { get; set; }
    public int? PreferredPaymentDay { get; set; }
    public decimal AdditionalFees { get; set; }
    public string? Notes { get; set; }
    public decimal? CurrentBalance { get; set; }
    public int? RemainingInstallments { get; set; }
    public decimal? AccruedInterestPending { get; set; }
    public DateTime? NextPaymentDate { get; set; }
    public decimal? CustomPeriodicPayment { get; set; }
    public decimal EarlyPaymentPenaltyRate { get; set; }
    public decimal EarlyPaymentPenaltyFixed { get; set; }
    public IReadOnlyList<int>? ReminderDays { get; set; }
    public bool RemindOnOverdue { get; set; } = true;
    public Guid? DefaultCategoryId { get; set; }
    public bool IsExistingLoan { get; set; }
}

public class UpdateLoanRequest
{
    public string Name { get; set; } = string.Empty;
    public string Creditor { get; set; } = string.Empty;
    public LoanType LoanType { get; set; }
    public decimal AnnualInterestRate { get; set; }
    public string? AssociatedAccountLabel { get; set; }
    public int? PreferredPaymentDay { get; set; }
    public decimal AdditionalFees { get; set; }
    public string? Notes { get; set; }
    public decimal EarlyPaymentPenaltyRate { get; set; }
    public decimal EarlyPaymentPenaltyFixed { get; set; }
    public IReadOnlyList<int>? ReminderDays { get; set; }
    public bool RemindOnOverdue { get; set; } = true;
    public Guid? DefaultCategoryId { get; set; }
    public decimal? CustomPeriodicPayment { get; set; }
    public bool RecalculateFutureSchedule { get; set; }
}

public class LoanInstallmentDto
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
    public decimal RemainingAmount { get; set; }
    public decimal RemainingBalanceAfter { get; set; }
    public LoanInstallmentStatus Status { get; set; }
    public bool IsLocked { get; set; }
}

public class LoanPaymentDto
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
    public string? CategoryName { get; set; }
    public Guid? TransactionId { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class RecordLoanPaymentRequest
{
    public decimal Amount { get; set; }
    public DateTime Date { get; set; }
    public LoanPaymentKind Kind { get; set; } = LoanPaymentKind.REGULAR;
    public Guid? InstallmentId { get; set; }
    public PaymentMethod PaymentMethod { get; set; } = PaymentMethod.BANK_TRANSFER;
    public Guid? CategoryId { get; set; }
    public bool CreateTransaction { get; set; } = true;
    public Guid? ExistingTransactionId { get; set; }
    public string? Notes { get; set; }
    public EarlyPaymentMode? EarlyPaymentMode { get; set; }
    public decimal? PenaltyAmount { get; set; }
}

public class CalculateLoanRequest
{
    public decimal Principal { get; set; }
    public decimal AnnualInterestRate { get; set; }
    public int TermMonths { get; set; }
    public LoanPaymentFrequency PaymentFrequency { get; set; } = LoanPaymentFrequency.MONTHLY;
    public AmortizationType AmortizationType { get; set; } = AmortizationType.FRENCH;
    public DateTime FirstInstallmentDate { get; set; }
    public int? PreferredPaymentDay { get; set; }
    public decimal AdditionalFees { get; set; }
    public decimal? CustomPeriodicPayment { get; set; }
}

public class AmortizationScheduleDto
{
    public decimal PeriodicPayment { get; set; }
    public decimal TotalInterest { get; set; }
    public decimal TotalPayment { get; set; }
    public decimal TotalPrincipal { get; set; }
    public DateTime EstimatedEndDate { get; set; }
    public int PeriodCount { get; set; }
    public bool IsEstimate { get; set; }
    public IReadOnlyList<AmortizationRowDto> Rows { get; set; } = Array.Empty<AmortizationRowDto>();
}

public class AmortizationRowDto
{
    public int Number { get; set; }
    public DateTime DueDate { get; set; }
    public decimal Principal { get; set; }
    public decimal Interest { get; set; }
    public decimal Fee { get; set; }
    public decimal Payment { get; set; }
    public decimal RemainingBalance { get; set; }
}

public class SimulateEarlyPaymentRequest
{
    public decimal ExtraPayment { get; set; }
    public EarlyPaymentMode Mode { get; set; } = EarlyPaymentMode.REDUCE_TERM;
    public decimal? PenaltyRate { get; set; }
    public decimal? PenaltyFixed { get; set; }
}

public class CompareEarlyPaymentsRequest
{
    public IReadOnlyList<decimal> ExtraPayments { get; set; } = Array.Empty<decimal>();
    public EarlyPaymentMode Mode { get; set; } = EarlyPaymentMode.REDUCE_TERM;
    public decimal? PenaltyRate { get; set; }
    public decimal? PenaltyFixed { get; set; }
}

public class EarlyPaymentScenarioDto
{
    public EarlyPaymentMode Mode { get; set; }
    public decimal ExtraPayment { get; set; }
    public decimal PenaltyAmount { get; set; }
    public decimal NewBalance { get; set; }
    public decimal PreviousPeriodicPayment { get; set; }
    public decimal NewPeriodicPayment { get; set; }
    public decimal PaymentReduction { get; set; }
    public int PreviousRemainingPeriods { get; set; }
    public int NewRemainingPeriods { get; set; }
    public int PeriodsSaved { get; set; }
    public DateTime? PreviousEndDate { get; set; }
    public DateTime? NewEndDate { get; set; }
    public int DaysSaved { get; set; }
    public decimal InterestWithoutExtra { get; set; }
    public decimal InterestWithExtra { get; set; }
    public decimal GrossInterestSaved { get; set; }
    public decimal NetInterestSaved { get; set; }
}

public class LoanDashboardDto
{
    public int ActiveLoans { get; set; }
    public decimal TotalOutstandingDebt { get; set; }
    public decimal TotalMonthlyInstallments { get; set; }
    public DateTime? NextDueDate { get; set; }
    public decimal NextDueAmount { get; set; }
    public string? NextDueLoanName { get; set; }
    public decimal TotalInterestPaid { get; set; }
    public decimal TotalPrincipalPaid { get; set; }
    public decimal TotalExtraPrincipalPaid { get; set; }
    public decimal TotalInterestSaved { get; set; }
    public decimal OverallPaidOffPercentage { get; set; }
    public IReadOnlyList<LoanBalancePointDto> DebtEvolution { get; set; } = Array.Empty<LoanBalancePointDto>();
    public IReadOnlyList<LoanDistributionDto> DebtDistribution { get; set; } = Array.Empty<LoanDistributionDto>();
    public decimal TotalCapitalPaid { get; set; }
    public decimal TotalInterestComponent { get; set; }
}

public class LoanBalancePointDto
{
    public DateTime Date { get; set; }
    public decimal Balance { get; set; }
}

public class LoanDistributionDto
{
    public Guid LoanId { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal Balance { get; set; }
    public decimal Percentage { get; set; }
}

public class LoanCalendarItemDto
{
    public Guid LoanId { get; set; }
    public string LoanName { get; set; } = string.Empty;
    public Guid? InstallmentId { get; set; }
    public int? InstallmentNumber { get; set; }
    public DateTime DueDate { get; set; }
    public decimal Amount { get; set; }
    public decimal RemainingAmount { get; set; }
    public LoanInstallmentStatus Status { get; set; }
    public bool IsExtraPayment { get; set; }
    public string Currency { get; set; } = "DOP";
}

public class LoanChangeLogDto
{
    public Guid Id { get; set; }
    public string Description { get; set; } = string.Empty;
    public string? Details { get; set; }
    public DateTime ChangedAt { get; set; }
}

public class UpdateLoanRemindersRequest
{
    public IReadOnlyList<int> ReminderDays { get; set; } = Array.Empty<int>();
    public bool RemindOnOverdue { get; set; } = true;
}
