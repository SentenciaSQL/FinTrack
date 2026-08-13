import 'package:fintrack/core/errors/api_exception.dart';
import 'package:fintrack/l10n/app_localizations.dart';

String mapErrorCode(AppLocalizations l10n, Object error) {
  final code = error is ApiException ? error.code : null;
  return switch (code) {
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
    _ => error is ApiException ? error.message : l10n.errorGeneric,
  };
}
