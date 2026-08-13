import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/core/models/models.dart';
import 'package:fintrack/features/dashboard/data/finance_repository.dart';

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) {
  return ref.watch(financeRepositoryProvider).dashboard();
});

final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) {
  return ref.watch(financeRepositoryProvider).categories();
});

class TransactionQuery {
  const TransactionQuery({
    this.type,
    this.search,
    this.categoryId,
  });

  final String? type;
  final String? search;
  final String? categoryId;

  TransactionQuery copyWith({String? type, String? search, String? categoryId, bool clearType = false}) {
    return TransactionQuery(
      type: clearType ? null : (type ?? this.type),
      search: search ?? this.search,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}

final transactionQueryProvider = StateProvider.autoDispose<TransactionQuery>((ref) => const TransactionQuery());

final transactionsProvider = FutureProvider.autoDispose<PagedTransactions>((ref) {
  final query = ref.watch(transactionQueryProvider);
  return ref.watch(financeRepositoryProvider).transactions(
        type: query.type,
        search: query.search,
        categoryId: query.categoryId,
      );
});

final transactionProvider = FutureProvider.autoDispose.family<Transaction, String>((ref, id) {
  return ref.watch(financeRepositoryProvider).transaction(id);
});

final budgetsProvider = FutureProvider.autoDispose<List<Budget>>((ref) {
  return ref.watch(financeRepositoryProvider).budgets();
});

final goalsProvider = FutureProvider.autoDispose<List<SavingsGoal>>((ref) {
  return ref.watch(financeRepositoryProvider).goals();
});

final contributionsProvider = FutureProvider.autoDispose.family<List<SavingsContribution>, String>((ref, id) {
  return ref.watch(financeRepositoryProvider).contributions(id);
});

final recurringProvider = FutureProvider.autoDispose<List<RecurringTransaction>>((ref) {
  return ref.watch(financeRepositoryProvider).recurring();
});

class ReportMonth {
  const ReportMonth(this.month, this.year);
  final int month;
  final int year;
}

final reportMonthProvider = StateProvider.autoDispose<ReportMonth>((ref) {
  final now = DateTime.now();
  return ReportMonth(now.month, now.year);
});

final monthlyReportProvider = FutureProvider.autoDispose<MonthlyReport>((ref) {
  final month = ref.watch(reportMonthProvider);
  return ref.watch(financeRepositoryProvider).monthlyReport(month.month, month.year);
});

final categoryExpensesProvider = FutureProvider.autoDispose<List<CategoryBreakdown>>((ref) {
  final month = ref.watch(reportMonthProvider);
  return ref.watch(financeRepositoryProvider).categoryExpenses(month.month, month.year);
});

final incomeVsExpensesProvider = FutureProvider.autoDispose<IncomeVsExpenses>((ref) {
  return ref.watch(financeRepositoryProvider).incomeVsExpenses();
});

final balanceHistoryProvider = FutureProvider.autoDispose<BalanceHistory>((ref) {
  return ref.watch(financeRepositoryProvider).balanceHistory();
});
