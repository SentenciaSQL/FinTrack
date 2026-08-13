import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/core/errors/error_mapper.dart';
import 'package:fintrack/core/extensions/context_extensions.dart';
import 'package:fintrack/core/localization/locale_provider.dart';
import 'package:fintrack/core/theme/theme_provider.dart';
import 'package:fintrack/core/utils/formatters.dart';
import 'package:fintrack/core/widgets/money.dart';
import 'package:fintrack/core/widgets/states.dart';
import 'package:fintrack/features/dashboard/data/finance_repository.dart';
import 'package:fintrack/features/dashboard/presentation/providers.dart';
import 'package:fintrack/l10n/app_localizations.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(budgetsProvider);
    final currency = ref.watch(currencyProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.budgets),
        actions: [IconButton(onPressed: () => _openForm(context, ref), icon: const Icon(Icons.add))],
      ),
      body: async.when(
        loading: () => const Padding(padding: EdgeInsets.all(16), child: FtSkeleton(height: 240)),
        error: (error, _) => FtErrorState(message: mapErrorCode(l10n, error), onRetry: () => ref.invalidate(budgetsProvider)),
        data: (items) {
          if (items.isEmpty) {
            return FtEmptyState(
              icon: Icons.pie_chart_outline,
              title: l10n.emptyBudgets,
              subtitle: l10n.emptyBudgetsHint,
              actionLabel: l10n.newBudget,
              onAction: () => _openForm(context, ref),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(budgetsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final budget = items[index];
                final name = categoryLabel(l10n, budget.categoryName, budget.categoryIsDefault);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(categoryIcon(budget.categoryIcon, 'EXPENSE')),
                            const SizedBox(width: 8),
                            Expanded(child: Text(name, style: context.texts.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                            Text(_status(l10n, budget.status), style: context.texts.labelLarge),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _row(l10n.budgets, MoneyFormatter.format(budget.amount, currency: currency, locale: locale)),
                        _row(l10n.spent, MoneyFormatter.format(budget.spent, currency: currency, locale: locale)),
                        _row(l10n.available, MoneyFormatter.format(budget.available, currency: currency, locale: locale)),
                        const SizedBox(height: 12),
                        ProgressBar(value: budget.usedPercentage),
                        const SizedBox(height: 8),
                        Text(l10n.percentUsed(budget.usedPercentage.toStringAsFixed(0))),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [Expanded(child: Text(label)), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))]),
    );
  }

  String _status(AppLocalizations l10n, String status) {
    return switch (status) {
      'WARNING' => l10n.budgetStatusWarning,
      'REACHED' => l10n.budgetStatusReached,
      'EXCEEDED' => l10n.budgetStatusExceeded,
      _ => l10n.budgetStatusOk,
    };
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final categories = (await ref.read(categoriesProvider.future)).where((c) => c.type == 'EXPENSE').toList();
    if (!context.mounted) {
      return;
    }
    final l10n = context.l10n;
    String? categoryId = categories.isEmpty ? null : categories.first.id;
    final amount = TextEditingController();
    final now = DateTime.now();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.newBudget, style: context.texts.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: categoryId,
                items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(categoryLabel(l10n, c.name, c.isDefault)))).toList(),
                onChanged: (value) => categoryId = value,
                decoration: InputDecoration(labelText: l10n.category),
              ),
              const SizedBox(height: 12),
              TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: l10n.amount)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final parsed = double.tryParse(amount.text.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0 || categoryId == null) {
                    return;
                  }
                  try {
                    await ref.read(financeRepositoryProvider).saveBudget(categoryId: categoryId!, amount: parsed, month: now.month, year: now.year);
                    ref.invalidate(budgetsProvider);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapErrorCode(l10n, error))));
                    }
                  }
                },
                child: Text(l10n.save),
              ),
            ],
          ),
        );
      },
    );
  }
}
