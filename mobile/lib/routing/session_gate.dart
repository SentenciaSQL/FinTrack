import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/features/auth/data/auth_repository.dart';
import 'package:fintrack/routing/auth_redirect.dart';

/// Maps the auth controller to a gate status.
///
/// A reload that still has the previous session is not treated as loading, so
/// an in-flight profile refresh cannot pin the user on the splash route.
AuthGateStatus authGateStatus(AsyncValue<AuthSession> auth) {
  if (auth.isLoading && !auth.hasValue) {
    return AuthGateStatus.loading;
  }
  if (auth.valueOrNull?.isAuthenticated == true) {
    return AuthGateStatus.signedIn;
  }
  return AuthGateStatus.signedOut;
}
