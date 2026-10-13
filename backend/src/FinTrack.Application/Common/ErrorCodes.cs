namespace FinTrack.Application.Common;

public static class ErrorCodes
{
    public const string ValidationError = "VALIDATION_ERROR";
    public const string InvalidAmount = "INVALID_AMOUNT";
    public const string InvalidEmail = "INVALID_EMAIL";
    public const string InvalidPassword = "INVALID_PASSWORD";
    public const string EmailAlreadyExists = "EMAIL_ALREADY_EXISTS";
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
    public const string SsoCancelled = "SSO_CANCELLED";
    public const string SsoExpired = "SSO_EXPIRED";
    public const string SsoProviderError = "SSO_PROVIDER_ERROR";
    public const string SsoEmailUnverified = "SSO_EMAIL_UNVERIFIED";
    public const string SsoEmailRequired = "SSO_EMAIL_REQUIRED";
    public const string SsoRegistrationDisabled = "SSO_REGISTRATION_DISABLED";
    public const string SsoIdentityInUse = "SSO_IDENTITY_IN_USE";
    public const string SsoAlreadyLinked = "SSO_ALREADY_LINKED";
    public const string SsoProviderAlreadyLinked = "SSO_PROVIDER_ALREADY_LINKED";
    public const string SsoLastSignInMethod = "SSO_LAST_SIGN_IN_METHOD";
    public const string SsoLinkUnavailable = "SSO_LINK_UNAVAILABLE";
    public const string SsoInvalid = "SSO_INVALID";
    public const string SsoDisabled = "SSO_DISABLED";
    public const string PasswordNotSet = "PASSWORD_NOT_SET";
    public const string PasswordAlreadySet = "PASSWORD_ALREADY_SET";
    public const string TooManyRequests = "TOO_MANY_REQUESTS";
}
