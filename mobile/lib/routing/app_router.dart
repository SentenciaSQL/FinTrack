import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fintrack/core/constants/storage_keys.dart';
import 'package:fintrack/core/storage/prefs_storage.dart';
import 'package:fintrack/features/auth/data/auth_repository.dart';
import 'package:fintrack/features/auth/data/biometric_auth.dart';
import 'package:fintrack/features/auth/presentation/auth_screens.dart';
import 'package:fintrack/features/auth/presentation/biometric_screen.dart';
import 'package:fintrack/features/auth/presentation/onboarding_screen.dart';
import 'package:fintrack/features/auth/presentation/splash_screen.dart';
import 'package:fintrack/routing/auth_redirect.dart';
import 'package:fintrack/routing/return_path.dart';
import 'package:fintrack/routing/session_gate.dart';
import 'package:fintrack/features/budgets/presentation/budgets_screen.dart';
import 'package:fintrack/features/dashboard/presentation/app_shell.dart';
import 'package:fintrack/features/dashboard/presentation/dashboard_screen.dart';
import 'package:fintrack/features/reports/presentation/reports_screen.dart';
import 'package:fintrack/features/settings/presentation/more_screens.dart';
import 'package:fintrack/features/transactions/presentation/transactions_screens.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final onboarding =
          ref
              .read(sharedPreferencesProvider)
              .getBool(StorageKeys.onboardingComplete) ??
          false;
      final status = authGateStatus(ref.read(authControllerProvider));
      final location = state.matchedLocation;
      final full = state.uri.hasQuery
          ? '$location?${state.uri.query}'
          : location;
      if (status == AuthGateStatus.signedOut &&
          !unauthenticatedEntryRoutes.contains(location)) {
        ref.read(returnPathProvider.notifier).remember(full);
      }
      final stored = ref.read(returnPathProvider);
      final target = resolveAppRedirect(
        status: status,
        onboardingComplete: onboarding,
        location: location,
        biometricLock: ref.read(biometricLockProvider),
        returnPath: stored,
      );
      if (target == null &&
          status == AuthGateStatus.signedIn &&
          stored != null &&
          sanitizeReturnPath(stored)?.split('?').first == location) {
        ref.read(returnPathProvider.notifier).clear();
      }
      return target;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/unlock',
        builder: (context, state) => const UnlockScreen(),
      ),
      GoRoute(
        path: '/transactions/new',
        builder: (context, state) => TransactionFormScreen(
          initialType: state.uri.queryParameters['type'],
        ),
      ),
      GoRoute(
        path: '/transactions/:id',
        builder: (context, state) =>
            TransactionDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/transactions/:id/edit',
        builder: (context, state) =>
            TransactionFormScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/savings',
        builder: (context, state) => const SavingsScreen(),
      ),
      GoRoute(
        path: '/recurring',
        builder: (context, state) => const RecurringScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/budgets',
                builder: (context, state) => const BudgetsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MoreScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    _authSub = ref.listen(authControllerProvider, (_, _) => notifyListeners());
    _lockSub = ref.listen(biometricLockProvider, (_, _) => notifyListeners());
  }

  late final ProviderSubscription<AsyncValue<AuthSession>> _authSub;
  late final ProviderSubscription<bool> _lockSub;

  @override
  void dispose() {
    _authSub.close();
    _lockSub.close();
    super.dispose();
  }
}
