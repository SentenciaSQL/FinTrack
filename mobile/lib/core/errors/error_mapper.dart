import 'package:fintrack/core/errors/api_exception.dart';
import 'package:fintrack/l10n/app_localizations.dart';

String mapErrorCode(AppLocalizations l10n, Object error) {
  final api = error is ApiException ? error : null;
  final known = switch (api?.code) {
    'INVALID_AMOUNT' => l10n.errInvalidAmount,
    'INVALID_EMAIL' => l10n.errInvalidEmail,
    'INVALID_PASSWORD' => l10n.errInvalidPassword,
    'EMAIL_ALREADY_EXISTS' => l10n.errEmailAlreadyExists,
    'INVALID_CREDENTIALS' => l10n.errInvalidCredentials,
    'RESOURCE_NOT_FOUND' => l10n.errResourceNotFound,
    'FORBIDDEN' => l10n.errForbidden,
    'VALIDATION_ERROR' => l10n.errValidation,
    'UNAUTHORIZED' => l10n.errUnauthorized,
    'CURRENT_PASSWORD_INCORRECT' => l10n.errCurrentPasswordIncorrect,
    'BUDGET_ALREADY_EXISTS' => l10n.errBudgetAlreadyExists,
    'CANNOT_DELETE_DEFAULT_CATEGORY' => l10n.errCannotDeleteDefaultCategory,
    'CATEGORY_TYPE_MISMATCH' => l10n.errCategoryTypeMismatch,
    'SSO_CANCELLED' => l10n.ssoCancelled,
    'SSO_EXPIRED' => l10n.ssoExpired,
    'SSO_PROVIDER_ERROR' => l10n.ssoProviderError,
    'SSO_EMAIL_UNVERIFIED' => l10n.ssoEmailUnverified,
    'SSO_EMAIL_REQUIRED' => l10n.ssoEmailRequired,
    'SSO_REGISTRATION_DISABLED' => l10n.ssoRegistrationDisabled,
    'SSO_IDENTITY_IN_USE' => l10n.ssoIdentityInUse,
    'SSO_ALREADY_LINKED' => l10n.ssoAlreadyLinked,
    'SSO_PROVIDER_ALREADY_LINKED' => l10n.ssoProviderAlreadyLinked,
    'SSO_LAST_SIGN_IN_METHOD' => l10n.ssoLastMethod,
    'SSO_LINK_UNAVAILABLE' => l10n.ssoLinkUnavailable,
    'SSO_INVALID' => l10n.ssoInvalid,
    'SSO_DISABLED' => l10n.ssoDisabled,
    'PASSWORD_NOT_SET' => l10n.passwordNotSet,
    'PASSWORD_ALREADY_SET' => l10n.passwordAlreadySet,
    'TOO_MANY_REQUESTS' => l10n.errTooManyRequests,
    'NETWORK_ERROR' => l10n.errNetwork,
    'SERVER_ERROR' || 'INTERNAL_ERROR' => l10n.errServer,
    _ => null,
  };
  if (known != null) {
    return known;
  }
  if (api != null) {
    if (api.statusCode == 401) {
      return l10n.errUnauthorized;
    }
    if (api.message.isNotEmpty && !isTechnicalErrorText(api.message)) {
      return api.message;
    }
    if (api.statusCode != null && api.statusCode! >= 500) {
      return l10n.errServer;
    }
  }
  return l10n.errServer;
}
