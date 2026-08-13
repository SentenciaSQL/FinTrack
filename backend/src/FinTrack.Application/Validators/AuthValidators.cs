using FluentValidation;
using FinTrack.Application.Common;
using FinTrack.Application.DTOs.Auth;

namespace FinTrack.Application.Validators;

public class RegisterRequestValidator : AbstractValidator<RegisterRequest>
{
    public RegisterRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty()
            .MaximumLength(120);

        RuleFor(x => x.Email)
            .NotEmpty()
            .EmailAddress()
            .WithErrorCode(ErrorCodes.InvalidEmail)
            .MaximumLength(256);

        RuleFor(x => x.Password)
            .NotEmpty()
            .MinimumLength(8)
            .WithErrorCode(ErrorCodes.InvalidPassword)
            .WithMessage("Password must be at least 8 characters");

        RuleFor(x => x.PreferredLanguage)
            .Must(v => v is null || v is "es" or "en")
            .WithMessage("Preferred language must be es or en");

        RuleFor(x => x.PreferredCurrency)
            .Must(v => v is null || v is "DOP" or "USD" or "EUR")
            .WithMessage("Preferred currency must be DOP, USD or EUR");
    }
}

public class LoginRequestValidator : AbstractValidator<LoginRequest>
{
    public LoginRequestValidator()
    {
        RuleFor(x => x.Email).NotEmpty().EmailAddress();
        RuleFor(x => x.Password).NotEmpty();
    }
}

public class UpdateProfileRequestValidator : AbstractValidator<UpdateProfileRequest>
{
    public UpdateProfileRequestValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(120);
        RuleFor(x => x.PreferredLanguage)
            .Must(v => v is null || v is "es" or "en")
            .WithMessage("Preferred language must be es or en");
        RuleFor(x => x.PreferredCurrency)
            .Must(v => v is null || v is "DOP" or "USD" or "EUR")
            .WithMessage("Preferred currency must be DOP, USD or EUR");
    }
}

public class ChangePasswordRequestValidator : AbstractValidator<ChangePasswordRequest>
{
    public ChangePasswordRequestValidator()
    {
        RuleFor(x => x.CurrentPassword).NotEmpty();
        RuleFor(x => x.NewPassword)
            .NotEmpty()
            .MinimumLength(8)
            .WithErrorCode(ErrorCodes.InvalidPassword);
    }
}
