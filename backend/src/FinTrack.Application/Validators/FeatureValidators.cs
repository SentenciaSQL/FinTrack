using FluentValidation;
using FinTrack.Application.Common;
using FinTrack.Application.DTOs.Budgets;
using FinTrack.Application.DTOs.Categories;
using FinTrack.Application.DTOs.Recurring;
using FinTrack.Application.DTOs.Savings;
using FinTrack.Application.DTOs.Transactions;

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
