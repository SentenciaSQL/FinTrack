/// Bootstrap state used by the router to decide the next screen.
enum AuthGateStatus {
  /// Session restore has not finished. Stay on the current route.
  loading,

  /// No usable access token.
  signedOut,

  /// A stored or freshly issued access token is available.
  signedIn,
}

/// Routes that a signed-out user may remain on after onboarding.
const authEntryRoutes = {'/login', '/register'};

/// Routes that only make sense before the user is inside the app.
const unauthenticatedEntryRoutes = {
  '/splash',
  '/onboarding',
  '/login',
  '/register',
  '/unlock',
};

/// Where to send the user, or null to keep [location].
///
/// `/splash` is only a waiting screen. Once session restore finishes, staying
/// there would freeze the app — including after a cold start when the user
/// comes back and the keystore read fails or returns no token.
String? resolveAppRedirect({
  required AuthGateStatus status,
  required bool onboardingComplete,
  required String location,
  bool biometricLock = false,
}) {
  if (status == AuthGateStatus.loading) {
    return null;
  }

  if (!onboardingComplete) {
    return location == '/onboarding' ? null : '/onboarding';
  }

  if (status == AuthGateStatus.signedOut) {
    return authEntryRoutes.contains(location) ? null : '/login';
  }

  if (biometricLock) {
    return location == '/unlock' ? null : '/unlock';
  }

  if (unauthenticatedEntryRoutes.contains(location)) {
    return '/home';
  }
  return null;
}
