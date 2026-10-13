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
        RuleFor(x => x.CurrentPassword).NotEmpty().MaximumLength(128);
        RuleFor(x => x.NewPassword)
            .NotEmpty()
            .MinimumLength(8)
            .MaximumLength(128)
            .WithErrorCode(ErrorCodes.InvalidPassword);
    }
}

public class SetInitialPasswordRequestValidator : AbstractValidator<SetInitialPasswordRequest>
{
    public SetInitialPasswordRequestValidator()
    {
        RuleFor(x => x.NewPassword)
            .NotEmpty()
            .MinimumLength(8)
            .MaximumLength(128)
            .WithErrorCode(ErrorCodes.InvalidPassword)
            .WithMessage("Password must be at least 8 characters");
    }
}

public class SsoStartRequestValidator : AbstractValidator<SsoStartRequest>
{
    public SsoStartRequestValidator()
    {
        RuleFor(x => x.Provider)
            .Must(SsoProviders.IsKnown)
            .WithErrorCode(ErrorCodes.SsoDisabled)
            .WithMessage("That sign-in method is not available");

        RuleFor(x => x.Intent)
            .Must(value => value is SsoIntents.SignIn or SsoIntents.Link)
            .WithErrorCode(ErrorCodes.ValidationError)
            .WithMessage("Sign-in intent is not valid");

        RuleFor(x => x.PreferredLanguage)
            .Must(value => value is null || value is "es" or "en")
            .WithMessage("Preferred language must be es or en");

        RuleFor(x => x.PreferredCurrency)
            .Must(value => value is null || value is "DOP" or "USD" or "EUR")
            .WithMessage("Preferred currency must be DOP, USD or EUR");
    }
}

public class SsoExchangeRequestValidator : AbstractValidator<SsoExchangeRequest>
{
    public SsoExchangeRequestValidator()
    {
        RuleFor(x => x.Code).NotEmpty().MaximumLength(200);
        RuleFor(x => x.State).NotEmpty().MaximumLength(200);
    }
}

public class SsoLinkRequestValidator : AbstractValidator<SsoLinkRequest>
{
    public SsoLinkRequestValidator()
    {
        RuleFor(x => x.LinkToken).NotEmpty().MaximumLength(200);
        RuleFor(x => x.Password).NotEmpty().MaximumLength(128);
    }
}
