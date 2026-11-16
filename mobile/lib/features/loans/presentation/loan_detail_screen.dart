import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fintrack/core/errors/error_mapper.dart';
import 'package:fintrack/core/extensions/context_extensions.dart';
import 'package:fintrack/core/localization/locale_provider.dart';
import 'package:fintrack/core/models/models.dart';
import 'package:fintrack/core/theme/theme_provider.dart';
import 'package:fintrack/core/utils/formatters.dart';
import 'package:fintrack/core/widgets/states.dart';
import 'package:fintrack/features/dashboard/data/finance_repository.dart';
import 'package:fintrack/features/dashboard/presentation/providers.dart';
import 'package:fintrack/l10n/app_localizations.dart';

class LoanDetailScreen extends ConsumerWidget {
  const LoanDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(loanProvider(id));
    final currency = ref.watch(currencyProvider);
    final locale = ref.watch(localeProvider);

    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.loans)),
        body: FtErrorState(message: mapErrorCode(l10n, error), onRetry: () => ref.invalidate(loanProvider(id))),
      ),
      data: (loan) => DefaultTabController(
        length: 6,
        child: Scaffold(
          appBar: AppBar(
            title: Text(loan.name),
            actions: [
              IconButton(
                onPressed: () => context.push('/loans/$id/edit'),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: () async {
                  await ref.read(financeRepositoryProvider).deleteLoan(id);
                  ref.invalidate(loansProvider);
                  ref.invalidate(loanDashboardProvider);
                  if (context.mounted) {
                    context.pop();
                  }
                },
                icon: const Icon(Icons.delete_outline),
              ),
            ],
            bottom: TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: l10n.summary),
                Tab(text: l10n.amortizationTable),
                Tab(text: l10n.installments),
                Tab(text: l10n.paymentHistory),
                Tab(text: l10n.earlyPaymentSimulator),
                Tab(text: l10n.configuration),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _SummaryTab(loan: loan, currency: currency, locale: locale),
              _AmortizationTab(loanId: id, currency: currency, locale: locale),
              _InstallmentsTab(loan: loan, currency: currency, locale: locale),
              _PaymentsTab(loan: loan, currency: currency, locale: locale),
              _SimulatorTab(loan: loan, currency: currency, locale: locale),
              _ConfigTab(loan: loan),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({required this.loan, required this.currency, required this.locale});
  final Loan loan;
  final String currency;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (loan.isEstimate)
          Card(
            color: context.colors.tertiaryContainer,
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.estimateDisclaimer),
            ),
          ),
        _kv(l10n.creditor, loan.creditor),
        _kv(l10n.loanType, loanTypeLabel(l10n, loan.loanType)),
        _kv(l10n.originalPrincipal, MoneyFormatter.format(loan.originalPrincipal, currency: currency, locale: locale)),
        _kv(l10n.currentBalance, MoneyFormatter.format(loan.currentBalance, currency: currency, locale: locale)),
        _kv(l10n.annualInterestRate, '${loan.annualInterestRate}%'),
        _kv(l10n.estimatedInstallment, MoneyFormatter.format(loan.periodicPayment, currency: currency, locale: locale)),
        _kv(l10n.remainingInstallments, '${loan.remainingInstallments}'),
        if (loan.nextPaymentDate != null) _kv(l10n.nextPaymentDate, DateFormatter.short(loan.nextPaymentDate!, locale)),
        _kv(l10n.totalInterestPaidLabel, MoneyFormatter.format(loan.totalInterestPaid, currency: currency, locale: locale)),
        _kv(l10n.totalPrincipalPaidLabel, MoneyFormatter.format(loan.totalPrincipalPaid, currency: currency, locale: locale)),
        _kv(l10n.extraPrincipalPaid, MoneyFormatter.format(loan.totalExtraPrincipalPaid, currency: currency, locale: locale)),
        _kv(l10n.interestSaved, MoneyFormatter.format(loan.totalInterestSaved, currency: currency, locale: locale)),
        const SizedBox(height: 12),
        Text(l10n.debtPaidPercent(loan.paidOffPercentage.toStringAsFixed(0))),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: (loan.paidOffPercentage / 100).clamp(0, 1)),
      ],
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(child: Text(k)),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _AmortizationTab extends ConsumerWidget {
  const _AmortizationTab({required this.loanId, required this.currency, required this.locale});
  final String loanId;
  final String currency;
  final Locale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(loanInstallmentsProvider(loanId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => FtErrorState(message: mapErrorCode(l10n, e), onRetry: () => ref.invalidate(loanInstallmentsProvider(loanId))),
      data: (rows) {
        if (rows.isEmpty) {
          return FtEmptyState(icon: Icons.table_rows_outlined, title: l10n.noInstallments, subtitle: '');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            return Card(
              child: ListTile(
                title: Text('${l10n.installment} #${row.number} · ${DateFormatter.short(row.dueDate, locale)}'),
                subtitle: Text(
                  '${l10n.capital}: ${MoneyFormatter.format(row.principalAmount, currency: currency, locale: locale)} · '
                  '${l10n.interest}: ${MoneyFormatter.format(row.interestAmount, currency: currency, locale: locale)}\n'
                  '${l10n.balance}: ${MoneyFormatter.format(row.remainingBalanceAfter, currency: currency, locale: locale)}',
                ),
                isThreeLine: true,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(MoneyFormatter.format(row.totalAmount, currency: currency, locale: locale), style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(installmentStatusLabel(l10n, row.status), style: TextStyle(color: _statusColor(context, row.status), fontSize: 12)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _InstallmentsTab extends ConsumerWidget {
  const _InstallmentsTab({required this.loan, required this.currency, required this.locale});
  final Loan loan;
  final String currency;
  final Locale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(loanInstallmentsProvider(loan.id));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => FtErrorState(message: mapErrorCode(l10n, e), onRetry: () => ref.invalidate(loanInstallmentsProvider(loan.id))),
      data: (items) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.icon(
                onPressed: () => _pay(context, ref, loan, null),
                icon: const Icon(Icons.payments_outlined),
                label: Text(l10n.registerPayment),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    leading: Icon(Icons.circle, size: 12, color: _statusColor(context, item.status)),
                    title: Text('#${item.number} · ${DateFormatter.short(item.dueDate, locale)}'),
                    subtitle: Text('${installmentStatusLabel(l10n, item.status)} · ${l10n.remaining}: ${MoneyFormatter.format(item.remainingAmount, currency: currency, locale: locale)}'),
                    trailing: item.status == 'PAID'
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : IconButton(
                            icon: const Icon(Icons.payment),
                            onPressed: () => _pay(context, ref, loan, item),
                          ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab({required this.loan, required this.currency, required this.locale});
  final Loan loan;
  final String currency;
  final Locale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(loanPaymentsProvider(loan.id));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => FtErrorState(message: mapErrorCode(l10n, e), onRetry: () => ref.invalidate(loanPaymentsProvider(loan.id))),
      data: (items) {
        if (items.isEmpty) {
          return FtEmptyState(icon: Icons.receipt_long_outlined, title: l10n.noPayments, subtitle: l10n.noPaymentsHint);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final p = items[index];
            return Card(
              child: ListTile(
                title: Text('${paymentKindLabel(l10n, p.kind)} · ${MoneyFormatter.format(p.amount, currency: currency, locale: locale)}'),
                subtitle: Text(
                  '${DateFormatter.short(p.date, locale)}\n'
                  '${l10n.capital}: ${MoneyFormatter.format(p.principalPortion, currency: currency, locale: locale)} · '
                  '${l10n.interest}: ${MoneyFormatter.format(p.interestPortion, currency: currency, locale: locale)}',
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}

class _SimulatorTab extends ConsumerStatefulWidget {
  const _SimulatorTab({required this.loan, required this.currency, required this.locale});
  final Loan loan;
  final String currency;
  final Locale locale;

  @override
  ConsumerState<_SimulatorTab> createState() => _SimulatorTabState();
}

class _SimulatorTabState extends ConsumerState<_SimulatorTab> {
  final _amount = TextEditingController(text: '25000');
  final _compare = TextEditingController(text: '25000,50000,100000');
  String _mode = 'REDUCE_TERM';
  EarlyPaymentScenario? _scenario;
  List<EarlyPaymentScenario> _scenarios = const [];
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _compare.dispose();
    super.dispose();
  }

  Future<void> _simulate() async {
    final value = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (value == null || value <= 0) {
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await ref.read(financeRepositoryProvider).simulateEarlyPayment(widget.loan.id, {
        'extraPayment': value,
        'mode': _mode,
      });
      setState(() => _scenario = result);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _compareScenarios() async {
    final amounts = _compare.text
        .split(RegExp(r'[,;\s]+'))
        .map((e) => double.tryParse(e.replaceAll(',', '.')))
        .whereType<double>()
        .where((e) => e > 0)
        .toList();
    if (amounts.isEmpty) {
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await ref.read(financeRepositoryProvider).compareEarlyPayments(widget.loan.id, {
        'extraPayments': amounts,
        'mode': _mode,
      });
      setState(() => _scenarios = result);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _confirm() async {
    final value = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (value == null || value <= 0) {
      return;
    }
    await ref.read(financeRepositoryProvider).recordLoanPayment(widget.loan.id, {
      'amount': value,
      'date': DateTime.now().toUtc().toIso8601String(),
      'kind': 'EXTRA_PRINCIPAL',
      'paymentMethod': 'BANK_TRANSFER',
      'createTransaction': widget.loan.defaultCategoryId != null,
      'categoryId': widget.loan.defaultCategoryId,
      'earlyPaymentMode': _mode,
    });
    ref.invalidate(loanProvider(widget.loan.id));
    ref.invalidate(loanInstallmentsProvider(widget.loan.id));
    ref.invalidate(loanPaymentsProvider(widget.loan.id));
    ref.invalidate(loansProvider);
    ref.invalidate(loanDashboardProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.extraPaymentConfirmed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = widget.currency;
    final locale = widget.locale;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.earlyPaymentSimulatorHint),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'REDUCE_TERM', label: Text(l10n.reduceTerm)),
            ButtonSegment(value: 'REDUCE_PAYMENT', label: Text(l10n.reducePayment)),
          ],
          selected: {_mode},
          onSelectionChanged: (v) => setState(() => _mode = v.first),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l10n.extraPaymentAmount),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton(onPressed: _busy ? null : _simulate, child: Text(l10n.simulate)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(onPressed: _busy || _scenario == null ? null : _confirm, child: Text(l10n.confirmExtraPayment)),
            ),
          ],
        ),
        if (_scenario != null) ...[
          const SizedBox(height: 16),
          _scenarioCard(l10n, _scenario!, currency, locale),
        ],
        const SizedBox(height: 20),
        Text(l10n.compareScenarios, style: context.texts.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextField(controller: _compare, decoration: InputDecoration(labelText: l10n.compareAmountsHint)),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: _busy ? null : _compareScenarios, child: Text(l10n.compare)),
        ..._scenarios.map((s) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _scenarioCard(l10n, s, currency, locale),
            )),
      ],
    );
  }

  Widget _scenarioCard(AppLocalizations l10n, EarlyPaymentScenario s, String currency, Locale locale) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.extraPaymentAmount}: ${MoneyFormatter.format(s.extraPayment, currency: currency, locale: locale)}', style: const TextStyle(fontWeight: FontWeight.w800)),
            Text('${l10n.newBalance}: ${MoneyFormatter.format(s.newBalance, currency: currency, locale: locale)}'),
            if (s.mode == 'REDUCE_PAYMENT') ...[
              Text('${l10n.newInstallment}: ${MoneyFormatter.format(s.newPeriodicPayment, currency: currency, locale: locale)}'),
              Text('${l10n.paymentReduction}: ${MoneyFormatter.format(s.paymentReduction, currency: currency, locale: locale)}'),
            ] else ...[
              Text('${l10n.periodsSaved}: ${s.periodsSaved}'),
              if (s.newEndDate != null) Text('${l10n.estimatedEnd}: ${DateFormatter.short(s.newEndDate!, locale)}'),
              Text('${l10n.timeSavedDays}: ${s.daysSaved}'),
            ],
            Text('${l10n.interestWithoutExtra}: ${MoneyFormatter.format(s.interestWithoutExtra, currency: currency, locale: locale)}'),
            Text('${l10n.interestWithExtra}: ${MoneyFormatter.format(s.interestWithExtra, currency: currency, locale: locale)}'),
            Text('${l10n.netInterestSaved}: ${MoneyFormatter.format(s.netInterestSaved, currency: currency, locale: locale)}'),
            if (s.penaltyAmount > 0) Text('${l10n.penalty}: ${MoneyFormatter.format(s.penaltyAmount, currency: currency, locale: locale)}'),
          ],
        ),
      ),
    );
  }
}

class _ConfigTab extends ConsumerStatefulWidget {
  const _ConfigTab({required this.loan});
  final Loan loan;

  @override
  ConsumerState<_ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends ConsumerState<_ConfigTab> {
  late final Set<int> _days;
  late bool _overdue;

  @override
  void initState() {
    super.initState();
    _days = {...widget.loan.reminderDays};
    _overdue = widget.loan.remindOnOverdue;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.reminders, style: context.texts.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final day in const [7, 3, 1, 0])
              FilterChip(
                label: Text(day == 0 ? l10n.sameDay : l10n.daysBefore(day)),
                selected: _days.contains(day),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _days.add(day);
                  } else {
                    _days.remove(day);
                  }
                }),
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.remindOnOverdue),
          value: _overdue,
          onChanged: (v) => setState(() => _overdue = v),
        ),
        FilledButton(
          onPressed: () async {
            await ref.read(financeRepositoryProvider).updateLoanReminders(
                  widget.loan.id,
                  reminderDays: _days.toList()..sort((a, b) => b.compareTo(a)),
                  remindOnOverdue: _overdue,
                );
            ref.invalidate(loanProvider(widget.loan.id));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.remindersSaved)));
            }
          },
          child: Text(l10n.save),
        ),
        const SizedBox(height: 16),
        Text(l10n.associatedAccount),
        Text(widget.loan.associatedAccountLabel?.isNotEmpty == true ? widget.loan.associatedAccountLabel! : l10n.optional),
        const SizedBox(height: 8),
        Text('${l10n.amortizationType}: ${amortizationLabel(l10n, widget.loan.amortizationType)}'),
        Text('${l10n.paymentFrequency}: ${loanFrequencyLabel(l10n, widget.loan.paymentFrequency)}'),
      ],
    );
  }
}

Future<void> _pay(BuildContext context, WidgetRef ref, Loan loan, LoanInstallment? installment) async {
  final l10n = context.l10n;
  final amountCtrl = TextEditingController(
    text: installment == null ? loan.periodicPayment.toStringAsFixed(2) : installment.remainingAmount.toStringAsFixed(2),
  );
  String kind = 'REGULAR';
  String method = 'BANK_TRANSFER';
  final categories = await ref.read(categoriesProvider.future);
  final expense = categories.where((c) => c.type == 'EXPENSE').toList();
  String? categoryId = loan.defaultCategoryId ?? (expense.isNotEmpty ? expense.first.id : null);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: StatefulBuilder(
          builder: (context, setModal) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.registerPayment, style: context.texts.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: kind,
                  decoration: InputDecoration(labelText: l10n.paymentKind),
                  items: [
                    for (final k in const ['REGULAR', 'PARTIAL', 'EXTRA_PRINCIPAL', 'FULL_PAYOFF', 'FEE'])
                      DropdownMenuItem(value: k, child: Text(paymentKindLabel(l10n, k))),
                  ],
                  onChanged: (v) => setModal(() => kind = v ?? kind),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.amount),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: method,
                  decoration: InputDecoration(labelText: l10n.paymentMethod),
                  items: [
                    for (final m in const ['CASH', 'DEBIT_CARD', 'CREDIT_CARD', 'BANK_TRANSFER', 'OTHER'])
                      DropdownMenuItem(value: m, child: Text(paymentMethodLabel(l10n, m))),
                  ],
                  onChanged: (v) => setModal(() => method = v ?? method),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: categoryId,
                  decoration: InputDecoration(labelText: l10n.category),
                  items: [
                    for (final c in expense)
                      DropdownMenuItem(value: c.id, child: Text(categoryLabel(l10n, c.name, c.isDefault))),
                  ],
                  onChanged: (v) => setModal(() => categoryId = v),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.'));
                    if (amount == null || amount <= 0) {
                      return;
                    }
                    await ref.read(financeRepositoryProvider).recordLoanPayment(loan.id, {
                      'amount': amount,
                      'date': DateTime.now().toUtc().toIso8601String(),
                      'kind': kind,
                      'installmentId': installment?.id,
                      'paymentMethod': method,
                      'categoryId': categoryId,
                      'createTransaction': categoryId != null,
                      if (kind == 'EXTRA_PRINCIPAL') 'earlyPaymentMode': 'REDUCE_TERM',
                    });
                    ref.invalidate(loanProvider(loan.id));
                    ref.invalidate(loanInstallmentsProvider(loan.id));
                    ref.invalidate(loanPaymentsProvider(loan.id));
                    ref.invalidate(loansProvider);
                    ref.invalidate(loanDashboardProvider);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(l10n.confirm),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

Color _statusColor(BuildContext context, String status) {
  return switch (status) {
    'PAID' => Colors.green,
    'OVERDUE' => context.colors.error,
    'DUE_SOON' => Colors.orange,
    'PARTIALLY_PAID' => Colors.blueGrey,
    _ => context.colors.primary,
  };
}
