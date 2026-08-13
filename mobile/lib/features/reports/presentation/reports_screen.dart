import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/core/errors/error_mapper.dart';
import 'package:fintrack/core/extensions/context_extensions.dart';
import 'package:fintrack/core/localization/locale_provider.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/theme/theme_provider.dart';
import 'package:fintrack/core/utils/formatters.dart';
import 'package:fintrack/core/widgets/money.dart';
import 'package:fintrack/core/widgets/states.dart';
import 'package:fintrack/features/dashboard/presentation/providers.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final month = ref.watch(reportMonthProvider);
    final monthly = ref.watch(monthlyReportProvider);
    final pie = ref.watch(categoryExpensesProvider);
    final bars = ref.watch(incomeVsExpensesProvider);
    final line = ref.watch(balanceHistoryProvider);
    final currency = ref.watch(currencyProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reports),
        actions: [
          IconButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(month.year, month.month),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                ref.read(reportMonthProvider.notifier).state = ReportMonth(picked.month, picked.year);
              }
            },
            icon: const Icon(Icons.calendar_month_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(monthlyReportProvider);
          ref.invalidate(categoryExpensesProvider);
          ref.invalidate(incomeVsExpensesProvider);
          ref.invalidate(balanceHistoryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            Text(DateFormatter.monthYear(month.month, month.year, locale), style: context.texts.titleMedium),
            const SizedBox(height: 12),
            monthly.when(
              loading: () => const FtSkeleton(height: 120),
              error: (error, _) => Text(mapErrorCode(l10n, error)),
              data: (data) => Row(
                children: [
                  Expanded(child: _stat(context, l10n.income, data.income, AppColors.income, currency, locale)),
                  const SizedBox(width: 8),
                  Expanded(child: _stat(context, l10n.expenses, data.expense, AppColors.expense, currency, locale)),
                  const SizedBox(width: 8),
                  Expanded(child: _stat(context, l10n.savings, data.savings, context.colors.primary, currency, locale)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FtSectionHeader(title: l10n.expensesByCategory),
            const SizedBox(height: 12),
            pie.when(
              loading: () => const FtSkeleton(height: 220),
              error: (error, _) => Text(mapErrorCode(l10n, error)),
              data: (items) {
                if (items.isEmpty) {
                  return FtEmptyState(icon: Icons.pie_chart_outline, title: l10n.emptyReports, subtitle: l10n.emptyReportsHint);
                }
                final colors = [context.colors.primary, AppColors.warning, AppColors.expense, const Color(0xFF6366F1), const Color(0xFF14B8A6)];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              centerSpaceRadius: 40,
                              sections: [
                                for (var i = 0; i < items.take(5).length; i++)
                                  PieChartSectionData(
                                    value: items[i].amount,
                                    color: colors[i % colors.length],
                                    title: '${items[i].percentage.toStringAsFixed(0)}%',
                                    radius: 52,
                                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FtSectionHeader(title: l10n.topCategories),
                        ...items.take(5).map((item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(categoryLabel(l10n, item.categoryName, item.categoryIsDefault)),
                              trailing: AmountText(amount: item.amount, currency: currency, locale: locale, isIncome: false, style: context.texts.bodyMedium),
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            FtSectionHeader(title: l10n.monthlyEvolution),
            const SizedBox(height: 12),
            bars.when(
              loading: () => const FtSkeleton(height: 220),
              error: (error, _) => Text(mapErrorCode(l10n, error)),
              data: (data) => Card(
                child: SizedBox(
                  height: 240,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))),
                        barGroups: [
                          for (var i = 0; i < data.points.length; i++)
                            BarChartGroupData(x: i, barRods: [
                              BarChartRodData(toY: data.points[i].income, color: AppColors.income, width: 7),
                              BarChartRodData(toY: data.points[i].expense, color: AppColors.expense, width: 7),
                            ]),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FtSectionHeader(title: l10n.balanceHistory),
            const SizedBox(height: 12),
            line.when(
              loading: () => const FtSkeleton(height: 220),
              error: (error, _) => Text(mapErrorCode(l10n, error)),
              data: (data) {
                if (data.points.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Card(
                  child: SizedBox(
                    height: 240,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              color: context.colors.primary,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                              spots: [
                                for (var i = 0; i < data.points.length; i++) FlSpot(i.toDouble(), data.points[i].balance),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, double amount, Color color, String currency, Locale locale) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label, style: context.texts.labelMedium),
            const SizedBox(height: 6),
            Text(MoneyFormatter.format(amount, currency: currency, locale: locale), style: context.texts.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
