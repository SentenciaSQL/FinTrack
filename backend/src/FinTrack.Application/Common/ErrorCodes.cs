namespace FinTrack.Application.Common;

public static class ErrorCodes
{
    public const string ValidationError = "VALIDATION_ERROR";
    public const string InvalidAmount = "INVALID_AMOUNT";
    public const string InvalidEmail = "INVALID_EMAIL";
    public const string InvalidPassword = "INVALID_PASSWORD";
    public const string EmailAlreadyExists = "EMAIL_ALREADY_EXISTS";
    public const string EmailNotVerified = "EMAIL_NOT_VERIFIED";
    public const string InvalidVerificationToken = "INVALID_VERIFICATION_TOKEN";
    public const string InvalidCredentials = "INVALID_CREDENTIALS";
    public const string ResourceNotFound = "RESOURCE_NOT_FOUND";
    public const string Forbidden = "FORBIDDEN";
    public const string CategoryRequired = "CATEGORY_REQUIRED";
    public const string CategoryTypeMismatch = "CATEGORY_TYPE_MISMATCH";
    public const string BudgetAlreadyExists = "BUDGET_ALREADY_EXISTS";
    public const string Unauthorized = "UNAUTHORIZED";
    public const string CurrentPasswordIncorrect = "CURRENT_PASSWORD_INCORRECT";
    public const string DescriptionTooLong = "DESCRIPTION_TOO_LONG";
    public const string InvalidDate = "INVALID_DATE";
    public const string CannotDeleteDefaultCategory = "CANNOT_DELETE_DEFAULT_CATEGORY";
    public const string InternalError = "INTERNAL_ERROR";
}