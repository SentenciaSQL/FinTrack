import 'package:fintrack/routing/startup_redirect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveStartupRedirect', () {
    test('stays on splash while auth is loading', () {
      expect(
        resolveStartupRedirect(
          location: '/splash',
          authLoading: true,
          loggedIn: false,
          onboardingComplete: true,
        ),
        isNull,
      );
    });

    test('stays on login while a sign-in request is in flight', () {
      expect(
        resolveStartupRedirect(
          location: '/login',
          authLoading: true,
          loggedIn: false,
          onboardingComplete: true,
        ),
        isNull,
      );
    });

    test('sends first launch from splash to onboarding', () {
      expect(
        resolveStartupRedirect(
          location: '/splash',
          authLoading: false,
          loggedIn: false,
          onboardingComplete: false,
        ),
        '/onboarding',
      );
    });

    test('sends returning logged-out users from splash to login', () {
      expect(
        resolveStartupRedirect(
          location: '/splash',
          authLoading: false,
          loggedIn: false,
          onboardingComplete: true,
        ),
        '/login',
      );
    });

    test('sends authenticated users from splash to home', () {
      expect(
        resolveStartupRedirect(
          location: '/splash',
          authLoading: false,
          loggedIn: true,
          onboardingComplete: true,
        ),
        '/home',
      );
    });

    test('leaves login and register alone when logged out', () {
      expect(
        resolveStartupRedirect(
          location: '/login',
          authLoading: false,
          loggedIn: false,
          onboardingComplete: true,
        ),
        isNull,
      );
      expect(
        resolveStartupRedirect(
          location: '/register',
          authLoading: false,
          loggedIn: false,
          onboardingComplete: true,
        ),
        isNull,
      );
    });

    test('sends logged-in users away from auth entry routes', () {
      expect(
        resolveStartupRedirect(
          location: '/login',
          authLoading: false,
          loggedIn: true,
          onboardingComplete: true,
        ),
        '/home',
      );
    });

    test('guards home when the session is missing', () {
      expect(
        resolveStartupRedirect(
          location: '/home',
          authLoading: false,
          loggedIn: false,
          onboardingComplete: true,
        ),
        '/login',
      );
    });
  });
}
