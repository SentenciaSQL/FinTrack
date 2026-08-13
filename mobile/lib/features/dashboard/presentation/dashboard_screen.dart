import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fintrack/core/errors/error_mapper.dart';
import 'package:fintrack/core/extensions/context_extensions.dart';
import 'package:fintrack/core/localization/locale_provider.dart';
import 'package:fintrack/core/models/models.dart';
import 'package:fintrack/core/notifications/notification_service.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/theme/theme_provider.dart';
import 'package:fintrack/core/utils/formatters.dart';
import 'package:fintrack/core/widgets/money.dart';
import 'package:fintrack/core/widgets/states.dart';
import 'package:fintrack/features/auth/data/auth_repository.dart';
import 'package:fintrack/features/dashboard/presentation/providers.dart';
import 'package:fintrack/l10n/app_localizations.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardProvider);
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final currency = ref.watch(currencyProvider);
    final locale = ref.watch(localeProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(user == null ? l10n.appName : l10n.welcomeBack(user.name.split(' ').first)),
      ),
      body: async.when(
        loading: () => const _DashboardSkeleton(),
        error: (error, _) => FtErrorState(
          message: mapErrorCode(l10n, error),
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
        data: (data) {
          _syncNotifications(ref, l10n);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(dashboardProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                _BalanceCard(data: data, currency: currency, locale: locale),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _MetricCard(label: l10n.monthlyIncome, amount: data.monthlyIncome, color: AppColors.income, currency: currency, locale: locale)),
                    const SizedBox(width: 12),
                    Expanded(child: _MetricCard(label: l10n.monthlyExpense, amount: data.monthlyExpense, color: AppColors.expense, currency: currency, locale: locale)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _MetricCard(label: l10n.monthlySavings, amount: data.monthlySavings, color: context.colors.primary, currency: currency, locale: locale)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.budgetUsed, style: context.texts.labelLarge),
                              const SizedBox(height: 12),
                              ProgressBar(value: data.budgetUsedPercentage),
                              const SizedBox(height: 8),
                              Text(l10n.percentUsed(data.budgetUsedPercentage.toStringAsFixed(0)), style: context.texts.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FtSectionHeader(title: l10n.incomeVsExpenses),
                const SizedBox(height: 12),
                Card(
                  child: SizedBox(
                    height: 220,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _IncomeExpenseChart(points: data.incomeVsExpenses),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FtSectionHeader(title: l10n.expensesByCategory),
                const SizedBox(height: 12),
                if (data.expensesByCategory.isEmpty)
                  Text(l10n.emptyReportsHint, style: context.texts.bodyMedium)
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          SizedBox(height: 180, child: _CategoryPie(items: data.expensesByCategory, l10n: l10n)),
                          const SizedBox(height: 12),
                          ...data.expensesByCategory.take(4).map((item) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(categoryIcon(item.categoryIcon, 'EXPENSE')),
                              title: Text(categoryLabel(l10n, item.categoryName, item.categoryIsDefault)),
                              trailing: AmountText(amount: item.amount, currency: currency, locale: locale, isIncome: false, style: context.texts.bodyMedium),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                FtSectionHeader(title: l10n.recentTransactions, action: l10n.seeAll, onAction: () => context.go('/transactions')),
                const SizedBox(height: 12),
                if (data.recentTransactions.isEmpty)
                  FtEmptyState(icon: Icons.receipt_long_outlined, title: l10n.emptyTransactions, subtitle: l10n.emptyTransactionsHint)
                else
                  ...data.recentTransactions.map((tx) => _TransactionTile(transaction: tx, currency: currency, locale: locale)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _syncNotifications(WidgetRef ref, AppLocalizations l10n) {
    Future.microtask(() async {
      final budgets = await ref.read(budgetsProvider.future);
      final goals = await ref.read(goalsProvider.future);
      final recurring = await ref.read(recurringProvider.future);
      await ref.read(notificationServiceProvider).syncAlerts(
            l10n: l10n,
            budgets: budgets,
            goals: goals,
            recurring: recurring,
          );
    });
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.data, required this.currency, required this.locale});
  final DashboardData data;
  final String currency;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.currentBalance, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            MoneyFormatter.format(data.currentBalance, currency: currency, locale: locale),
            style: context.texts.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.amount, required this.color, required this.currency, required this.locale});
  final String label;
  final double amount;
  final Color color;
  final String currency;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: context.texts.labelLarge),
            const SizedBox(height: 8),
            Text(MoneyFormatter.format(amount, currency: currency, locale: locale), style: context.texts.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _IncomeExpenseChart extends StatelessWidget {
  const _IncomeExpenseChart({required this.points});
  final List<IncomeExpensePoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return Text(points[index].label, style: const TextStyle(fontSize: 11));
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: [
                BarChartRodData(toY: points[i].income, color: AppColors.income, width: 8, borderRadius: BorderRadius.circular(4)),
                BarChartRodData(toY: points[i].expense, color: AppColors.expense, width: 8, borderRadius: BorderRadius.circular(4)),
              ],
            ),
        ],
      ),
    );
  }
}

class _CategoryPie extends StatelessWidget {
  const _CategoryPie({required this.items, required this.l10n});
  final List<CategoryBreakdown> items;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = [context.colors.primary, AppColors.warning, AppColors.expense, const Color(0xFF6366F1), const Color(0xFF14B8A6)];
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 36,
        sections: [
          for (var i = 0; i < items.length && i < 5; i++)
            PieChartSectionData(
              value: items[i].amount,
              color: colors[i % colors.length],
              title: '${items[i].percentage.toStringAsFixed(0)}%',
              radius: 48,
              titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction, required this.currency, required this.locale});
  final Transaction transaction;
  final String currency;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final income = transaction.type == 'INCOME';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => context.push('/transactions/${transaction.id}'),
        leading: CircleAvatar(
          backgroundColor: (income ? AppColors.income : AppColors.expense).withValues(alpha: 0.12),
          child: Icon(categoryIcon(transaction.categoryIcon, transaction.type), color: income ? AppColors.income : AppColors.expense),
        ),
        title: Text(transaction.description, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(categoryLabel(context.l10n, transaction.categoryName, transaction.categoryIsDefault)),
        trailing: AmountText(amount: transaction.amount, currency: currency, locale: locale, isIncome: income, style: context.texts.bodyLarge),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        FtSkeleton(height: 140),
        SizedBox(height: 16),
        FtSkeleton(height: 90),
        SizedBox(height: 16),
        FtSkeleton(height: 220),
      ],
    );
  }
}
