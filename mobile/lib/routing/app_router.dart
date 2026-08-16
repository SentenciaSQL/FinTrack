import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fintrack/core/constants/storage_keys.dart';
import 'package:fintrack/core/storage/prefs_storage.dart';
import 'package:fintrack/features/auth/data/auth_repository.dart';
import 'package:fintrack/features/auth/presentation/auth_screens.dart';
import 'package:fintrack/features/auth/presentation/onboarding_screen.dart';
import 'package:fintrack/features/auth/presentation/splash_screen.dart';
import 'package:fintrack/features/budgets/presentation/budgets_screen.dart';
import 'package:fintrack/features/dashboard/presentation/app_shell.dart';
import 'package:fintrack/features/dashboard/presentation/dashboard_screen.dart';
import 'package:fintrack/features/reports/presentation/reports_screen.dart';
import 'package:fintrack/features/settings/presentation/more_screens.dart';
import 'package:fintrack/features/transactions/presentation/transactions_screens.dart';
import 'package:fintrack/routing/startup_redirect.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final onboarding = ref.read(sharedPreferencesProvider).getBool(StorageKeys.onboardingComplete) ?? false;
      return resolveStartupRedirect(
        location: state.matchedLocation,
        authLoading: auth.isLoading,
        loggedIn: auth.valueOrNull?.isAuthenticated == true,
        onboardingComplete: onboarding,
      );
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(
        path: '/transactions/new',
        builder: (context, state) => TransactionFormScreen(initialType: state.uri.queryParameters['type']),
      ),
      GoRoute(
        path: '/transactions/:id',
        builder: (context, state) => TransactionDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/transactions/:id/edit',
        builder: (context, state) => TransactionFormScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/categories', builder: (context, state) => const CategoriesScreen()),
      GoRoute(path: '/savings', builder: (context, state) => const SavingsScreen()),
      GoRoute(path: '/recurring', builder: (context, state) => const RecurringScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (context, state) => const DashboardScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/transactions', builder: (context, state) => const TransactionsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/budgets', builder: (context, state) => const BudgetsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/more', builder: (context, state) => const MoreScreen())]),
        ],
      ),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    _sub = ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }

  late final ProviderSubscription<AsyncValue<AuthSession>> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
