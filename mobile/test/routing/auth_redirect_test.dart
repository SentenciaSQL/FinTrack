import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fintrack/features/auth/data/auth_repository.dart';
import 'package:fintrack/routing/auth_redirect.dart';
import 'package:fintrack/routing/session_gate.dart';

void main() {
  test('signed-out session leaves splash after onboarding', () {
    expect(
      resolveAppRedirect(
        status: AuthGateStatus.signedOut,
        onboardingComplete: true,
        location: '/splash',
      ),
      '/login',
    );
  });

  test('signed-in session leaves splash for home', () {
    expect(
      resolveAppRedirect(
        status: AuthGateStatus.signedIn,
        onboardingComplete: true,
        location: '/splash',
      ),
      '/home',
    );
  });

  test('loading session stays on splash', () {
    expect(
      resolveAppRedirect(
        status: AuthGateStatus.loading,
        onboardingComplete: true,
        location: '/splash',
      ),
      isNull,
    );
  });

  test('loading session does not pull an open screen back to splash', () {
    expect(
      resolveAppRedirect(
        status: AuthGateStatus.loading,
        onboardingComplete: true,
        location: '/home',
      ),
      isNull,
    );
  });

  test('signed-out user can stay on login and register', () {
    expect(
      resolveAppRedirect(
        status: AuthGateStatus.signedOut,
        onboardingComplete: true,
        location: '/login',
      ),
      isNull,
    );
    expect(
      resolveAppRedirect(
        status: AuthGateStatus.signedOut,
        onboardingComplete: true,
        location: '/register',
      ),
      isNull,
    );
  });

  test('signed-out user is sent to login from a protected route', () {
    expect(
      resolveAppRedirect(
        status: AuthGateStatus.signedOut,
        onboardingComplete: true,
        location: '/home',
      ),
      '/login',
    );
  });

  test('signed-in user leaves auth screens', () {
    for (final location in ['/login', '/register', '/onboarding']) {
      expect(
        resolveAppRedirect(
          status: AuthGateStatus.signedIn,
          onboardingComplete: true,
          location: location,
        ),
        '/home',
      );
    }
  });

  test('incomplete onboarding always opens onboarding', () {
    expect(
      resolveAppRedirect(
        status: AuthGateStatus.signedOut,
        onboardingComplete: false,
        location: '/splash',
      ),
      '/onboarding',
    );
    expect(
      resolveAppRedirect(
        status: AuthGateStatus.signedIn,
        onboardingComplete: false,
        location: '/home',
      ),
      '/onboarding',
    );
    expect(
      resolveAppRedirect(
        status: AuthGateStatus.signedOut,
        onboardingComplete: false,
        location: '/onboarding',
      ),
      isNull,
    );
  });

  test('auth gate treats a reload that still has a session as signed in', () {
    const session = AuthSession(token: 'stored-token');
    final reloading = const AsyncLoading<AuthSession>().copyWithPrevious(
      const AsyncData(session),
    );

    expect(
      authGateStatus(const AsyncLoading<AuthSession>()),
      AuthGateStatus.loading,
    );
    expect(
      authGateStatus(const AsyncData(AuthSession())),
      AuthGateStatus.signedOut,
    );
    expect(authGateStatus(const AsyncData(session)), AuthGateStatus.signedIn);
    expect(authGateStatus(reloading), AuthGateStatus.signedIn);
    expect(
      authGateStatus(AsyncError<AuthSession>(Exception('x'), StackTrace.empty)),
      AuthGateStatus.signedOut,
    );
  });

  testWidgets('router leaves splash once a signed-out session resolves', (
    tester,
  ) async {
    final status = ValueNotifier(AuthGateStatus.loading);
    final router = _router(status);
    addTearDown(status.dispose);
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('splash-screen'), findsOneWidget);

    status.value = AuthGateStatus.signedOut;
    await tester.pumpAndSettle();

    expect(find.text('login-screen'), findsOneWidget);
    expect(find.text('splash-screen'), findsNothing);
  });

  test('signed-in session with fingerprint lock opens the unlock screen', () {
    expect(
      resolveAppRedirect(
        status: AuthGateStatus.signedIn,
        onboardingComplete: true,
        location: '/splash',
        biometricLock: true,
      ),
      '/unlock',
    );
    expect(
      resolveAppRedirect(
        status: AuthGateStatus.signedIn,
        onboardingComplete: true,
        location: '/home',
        biometricLock: true,
      ),
      '/unlock',
    );
    expect(
      resolveAppRedirect(
        status: AuthGateStatus.signedIn,
        onboardingComplete: true,
        location: '/unlock',
        biometricLock: true,
      ),
      isNull,
    );
  });

  test('unlocked session leaves the fingerprint screen', () {
    expect(
      resolveAppRedirect(
        status: AuthGateStatus.signedIn,
        onboardingComplete: true,
        location: '/unlock',
      ),
      '/home',
    );
  });

  test('signed-out user cannot stay on the fingerprint screen', () {
    expect(
      resolveAppRedirect(
        status: AuthGateStatus.signedOut,
        onboardingComplete: true,
        location: '/unlock',
      ),
      '/login',
    );
  });

  testWidgets('router leaves splash for home when the session is restored', (
    tester,
  ) async {
    final status = ValueNotifier(AuthGateStatus.loading);
    final router = _router(status);
    addTearDown(status.dispose);
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    status.value = AuthGateStatus.signedIn;
    await tester.pumpAndSettle();

    expect(find.text('home-screen'), findsOneWidget);
    expect(find.text('splash-screen'), findsNothing);
  });
}

GoRouter _router(ValueNotifier<AuthGateStatus> status) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: status,
    redirect: (context, state) {
      return resolveAppRedirect(
        status: status.value,
        onboardingComplete: true,
        location: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Text('splash-screen'),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Text('login-screen'),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const Text('home-screen'),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const Text('onboarding-screen'),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const Text('register-screen'),
      ),
    ],
  );
}
