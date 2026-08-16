/// Startup navigation after the splash route.
///
/// `/splash` is only valid while the session is being restored. Treating it as a
/// public page left returning users parked on splash forever.
String? resolveStartupRedirect({
  required String location,
  required bool authLoading,
  required bool loggedIn,
  required bool onboardingComplete,
}) {
  if (authLoading) {
    return null;
  }

  if (!onboardingComplete) {
    return location == '/onboarding' ? null : '/onboarding';
  }

  const authRoutes = {'/login', '/register'};
  const entryRoutes = {'/splash', '/onboarding', '/login', '/register'};

  if (!loggedIn) {
    return authRoutes.contains(location) ? null : '/login';
  }

  if (entryRoutes.contains(location)) {
    return '/home';
  }

  return null;
}
