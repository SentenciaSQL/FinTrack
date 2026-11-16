using FluentValidation;
using FinTrack.Application.Common;
using FinTrack.Application.DTOs.Budgets;
using FinTrack.Application.DTOs.Categories;
using FinTrack.Application.DTOs.Loans;
using FinTrack.Application.DTOs.Recurring;
using FinTrack.Application.DTOs.Savings;
using FinTrack.Application.DTOs.Transactions;
using FinTrack.Domain.Enums;

namespace FinTrack.Application.Validators;

public class CreateCategoryRequestValidator : AbstractValidator<CreateCategoryRequest>
{
    public CreateCategoryRequestValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(80);
        RuleFor(x => x.Type).IsInEnum();
        RuleFor(x => x.Icon).MaximumLength(80);
    }
}

public class UpdateCategoryRequestValidator : AbstractValidator<UpdateCategoryRequest>
{
    public UpdateCategoryRequestValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(80);
        RuleFor(x => x.Icon).MaximumLength(80);
    }
}

public class CreateTransactionRequestValidator : AbstractValidator<CreateTransactionRequest>
{
    public CreateTransactionRequestValidator()
    {
        RuleFor(x => x.Amount)
            .GreaterThan(0)
            .WithErrorCode(ErrorCodes.InvalidAmount)
            .WithMessage("Amount must be greater than zero");
        RuleFor(x => x.Description)
            .NotEmpty()
            .MaximumLength(200)
            .WithErrorCode(ErrorCodes.DescriptionTooLong);
        RuleFor(x => x.Date).NotEmpty().WithErrorCode(ErrorCodes.InvalidDate);
        RuleFor(x => x.CategoryId).NotEmpty().WithErrorCode(ErrorCodes.CategoryRequired);
        RuleFor(x => x.Type).IsInEnum();
        RuleFor(x => x.PaymentMethod).IsInEnum();
        RuleFor(x => x.Notes).MaximumLength(500);
    }
}

public class UpdateTransactionRequestValidator : AbstractValidator<UpdateTransactionRequest>
{
    public UpdateTransactionRequestValidator()
    {
        RuleFor(x => x.Amount).GreaterThan(0).WithErrorCode(ErrorCodes.InvalidAmount);
        RuleFor(x => x.Description).NotEmpty().MaximumLength(200);
        RuleFor(x => x.Date).NotEmpty();
        RuleFor(x => x.CategoryId).NotEmpty().WithErrorCode(ErrorCodes.CategoryRequired);
        RuleFor(x => x.Type).IsInEnum();
        RuleFor(x => x.PaymentMethod).IsInEnum();
        RuleFor(x => x.Notes).MaximumLength(500);
    }
}

public class CreateBudgetRequestValidator : AbstractValidator<CreateBudgetRequest>
{
    public CreateBudgetRequestValidator()
    {
        RuleFor(x => x.Amount).GreaterThan(0).WithErrorCode(ErrorCodes.InvalidAmount);
        RuleFor(x => x.CategoryId).NotEmpty().WithErrorCode(ErrorCodes.CategoryRequired);
        RuleFor(x => x.Month).InclusiveBetween(1, 12);
        RuleFor(x => x.Year).InclusiveBetween(2000, 2100);
    }
}

public class UpdateBudgetRequestValidator : AbstractValidator<UpdateBudgetRequest>
{
    public UpdateBudgetRequestValidator()
    {
        RuleFor(x => x.Amount).GreaterThan(0).WithErrorCode(ErrorCodes.InvalidAmount);
    }
}

public class CreateSavingsGoalRequestValidator : AbstractValidator<CreateSavingsGoalRequest>
{
    public CreateSavingsGoalRequestValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(120);
        RuleFor(x => x.Description).MaximumLength(500);
        RuleFor(x => x.TargetAmount).GreaterThan(0).WithErrorCode(ErrorCodes.InvalidAmount);
    }
}

public class UpdateSavingsGoalRequestValidator : AbstractValidator<UpdateSavingsGoalRequest>
{
    public UpdateSavingsGoalRequestValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(120);
        RuleFor(x => x.Description).MaximumLength(500);
        RuleFor(x => x.TargetAmount).GreaterThan(0).WithErrorCode(ErrorCodes.InvalidAmount);
    }
}

public class CreateContributionRequestValidator : AbstractValidator<CreateContributionRequest>
{
    public CreateContributionRequestValidator()
    {
        RuleFor(x => x.Amount).GreaterThan(0).WithErrorCode(ErrorCodes.InvalidAmount);
        RuleFor(x => x.Date).NotEmpty();
    }
}

public class CreateRecurringTransactionRequestValidator : AbstractValidator<CreateRecurringTransactionRequest>
{
    public CreateRecurringTransactionRequestValidator()
    {
        RuleFor(x => x.Amount).GreaterThan(0).WithErrorCode(ErrorCodes.InvalidAmount);
        RuleFor(x => x.Description).NotEmpty().MaximumLength(200);
        RuleFor(x => x.CategoryId).NotEmpty().WithErrorCode(ErrorCodes.CategoryRequired);
        RuleFor(x => x.Type).IsInEnum();
        RuleFor(x => x.Frequency).IsInEnum();
        RuleFor(x => x.NextExecutionDate).NotEmpty();
    }
}

public class UpdateRecurringTransactionRequestValidator : AbstractValidator<UpdateRecurringTransactionRequest>
{
    public UpdateRecurringTransactionRequestValidator()
    {
        RuleFor(x => x.Amount).GreaterThan(0).WithErrorCode(ErrorCodes.InvalidAmount);
        RuleFor(x => x.Description).NotEmpty().MaximumLength(200);
        RuleFor(x => x.CategoryId).NotEmpty().WithErrorCode(ErrorCodes.CategoryRequired);
        RuleFor(x => x.Type).IsInEnum();
        RuleFor(x => x.Frequency).IsInEnum();
        RuleFor(x => x.NextExecutionDate).NotEmpty();
    }
}

public class CreateLoanRequestValidator : AbstractValidator<CreateLoanRequest>
{
    public CreateLoanRequestValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(120);
        RuleFor(x => x.Creditor).NotEmpty().MaximumLength(120);
        RuleFor(x => x.LoanType).IsInEnum();
        RuleFor(x => x.OriginalPrincipal).GreaterThan(0).WithErrorCode(ErrorCodes.InvalidAmount);
        RuleFor(x => x.Currency).NotEmpty().MaximumLength(8);
        RuleFor(x => x.AnnualInterestRate).GreaterThanOrEqualTo(0).LessThanOrEqualTo(1000);
        RuleFor(x => x.DisbursementDate).NotEmpty();
        RuleFor(x => x.FirstInstallmentDate).NotEmpty();
        RuleFor(x => x.TermMonths).InclusiveBetween(1, 600);
        RuleFor(x => x.PaymentFrequency).IsInEnum();
        RuleFor(x => x.AmortizationType).IsInEnum();
        RuleFor(x => x.AssociatedAccountLabel).MaximumLength(120);
        RuleFor(x => x.PreferredPaymentDay).InclusiveBetween(1, 28).When(x => x.PreferredPaymentDay.HasValue);
        RuleFor(x => x.AdditionalFees).GreaterThanOrEqualTo(0);
        RuleFor(x => x.Notes).MaximumLength(1000);
        RuleFor(x => x.CurrentBalance).GreaterThan(0).When(x => x.CurrentBalance.HasValue).WithErrorCode(ErrorCodes.InvalidAmount);
        RuleFor(x => x.RemainingInstallments).InclusiveBetween(1, 600).When(x => x.RemainingInstallments.HasValue);
        RuleFor(x => x.EarlyPaymentPenaltyRate).GreaterThanOrEqualTo(0);
        RuleFor(x => x.EarlyPaymentPenaltyFixed).GreaterThanOrEqualTo(0);
        RuleFor(x => x.CustomPeriodicPayment).GreaterThan(0)
            .When(x => x.AmortizationType == AmortizationType.CUSTOM)
            .WithErrorCode(ErrorCodes.InvalidAmount);
    }
}

public class UpdateLoanRequestValidator : AbstractValidator<UpdateLoanRequest>
{
    public UpdateLoanRequestValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(120);
        RuleFor(x => x.Creditor).NotEmpty().MaximumLength(120);
        RuleFor(x => x.LoanType).IsInEnum();
        RuleFor(x => x.AnnualInterestRate).GreaterThanOrEqualTo(0).LessThanOrEqualTo(1000);
        RuleFor(x => x.AssociatedAccountLabel).MaximumLength(120);
        RuleFor(x => x.PreferredPaymentDay).InclusiveBetween(1, 28).When(x => x.PreferredPaymentDay.HasValue);
        RuleFor(x => x.AdditionalFees).GreaterThanOrEqualTo(0);
        RuleFor(x => x.Notes).MaximumLength(1000);
        RuleFor(x => x.EarlyPaymentPenaltyRate).GreaterThanOrEqualTo(0);
        RuleFor(x => x.EarlyPaymentPenaltyFixed).GreaterThanOrEqualTo(0);
        RuleFor(x => x.CustomPeriodicPayment).GreaterThan(0).When(x => x.CustomPeriodicPayment.HasValue);
    }
}

public class RecordLoanPaymentRequestValidator : AbstractValidator<RecordLoanPaymentRequest>
{
    public RecordLoanPaymentRequestValidator()
    {
        RuleFor(x => x.Amount).GreaterThan(0).WithErrorCode(ErrorCodes.InvalidAmount);
        RuleFor(x => x.Date).NotEmpty();
        RuleFor(x => x.Kind).IsInEnum();
        RuleFor(x => x.PaymentMethod).IsInEnum();
        RuleFor(x => x.Notes).MaximumLength(500);
        RuleFor(x => x.EarlyPaymentMode).IsInEnum().When(x => x.EarlyPaymentMode.HasValue);
        RuleFor(x => x.PenaltyAmount).GreaterThanOrEqualTo(0).When(x => x.PenaltyAmount.HasValue);
    }
}

public class CalculateLoanRequestValidator : AbstractValidator<CalculateLoanRequest>
{
    public CalculateLoanRequestValidator()
    {
        RuleFor(x => x.Principal).GreaterThan(0).WithErrorCode(ErrorCodes.InvalidAmount);
        RuleFor(x => x.AnnualInterestRate).GreaterThanOrEqualTo(0).LessThanOrEqualTo(1000);
        RuleFor(x => x.TermMonths).InclusiveBetween(1, 600);
        RuleFor(x => x.PaymentFrequency).IsInEnum();
        RuleFor(x => x.AmortizationType).IsInEnum();
        RuleFor(x => x.FirstInstallmentDate).NotEmpty();
        RuleFor(x => x.PreferredPaymentDay).InclusiveBetween(1, 28).When(x => x.PreferredPaymentDay.HasValue);
        RuleFor(x => x.AdditionalFees).GreaterThanOrEqualTo(0);
        RuleFor(x => x.CustomPeriodicPayment).GreaterThan(0)
            .When(x => x.AmortizationType == AmortizationType.CUSTOM)
            .WithErrorCode(ErrorCodes.InvalidAmount);
    }
}

public class SimulateEarlyPaymentRequestValidator : AbstractValidator<SimulateEarlyPaymentRequest>
{
    public SimulateEarlyPaymentRequestValidator()
    {
        RuleFor(x => x.ExtraPayment).GreaterThan(0).WithErrorCode(ErrorCodes.InvalidAmount);
        RuleFor(x => x.Mode).IsInEnum();
        RuleFor(x => x.PenaltyRate).GreaterThanOrEqualTo(0).When(x => x.PenaltyRate.HasValue);
        RuleFor(x => x.PenaltyFixed).GreaterThanOrEqualTo(0).When(x => x.PenaltyFixed.HasValue);
    }
}
