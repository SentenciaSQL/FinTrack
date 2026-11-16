import 'package:fl_chart/fl_chart.dart';
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

class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final loansAsync = ref.watch(loansProvider);
    final dashAsync = ref.watch(loanDashboardProvider);
    final currency = ref.watch(currencyProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loans),
        actions: [
          IconButton(
            tooltip: l10n.loanCalculator,
            onPressed: () => context.push('/loans/calculator'),
            icon: const Icon(Icons.calculate_outlined),
          ),
          IconButton(
            tooltip: l10n.loanCalendar,
            onPressed: () => context.push('/loans/calendar'),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            onPressed: () => context.push('/loans/new'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: loansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => FtErrorState(
          message: mapErrorCode(l10n, error),
          onRetry: () {
            ref.invalidate(loansProvider);
            ref.invalidate(loanDashboardProvider);
          },
        ),
        data: (loans) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(loansProvider);
              ref.invalidate(loanDashboardProvider);
              await ref.read(loansProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                dashAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (dash) => _LoanDashboardCard(dash: dash, currency: currency, locale: locale, l10n: l10n),
                ),
                const SizedBox(height: 16),
                Text(l10n.myLoans, style: context.texts.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (loans.isEmpty)
                  FtEmptyState(
                    icon: Icons.account_balance_outlined,
                    title: l10n.emptyLoans,
                    subtitle: l10n.emptyLoansHint,
                    actionLabel: l10n.newLoan,
                    onAction: () => context.push('/loans/new'),
                  )
                else
                  ...loans.map((loan) => _LoanListTile(loan: loan, currency: currency, locale: locale)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LoanDashboardCard extends StatelessWidget {
  const _LoanDashboardCard({
    required this.dash,
    required this.currency,
    required this.locale,
    required this.l10n,
  });

  final LoanDashboard dash;
  final String currency;
  final Locale locale;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.loansDashboard, style: context.texts.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _metric(context, l10n.activeLoans, '${dash.activeLoans}'),
                _metric(context, l10n.totalDebt, MoneyFormatter.format(dash.totalOutstandingDebt, currency: currency, locale: locale)),
                _metric(context, l10n.monthlyInstallments, MoneyFormatter.format(dash.totalMonthlyInstallments, currency: currency, locale: locale)),
                _metric(context, l10n.interestSaved, MoneyFormatter.format(dash.totalInterestSaved, currency: currency, locale: locale)),
              ],
            ),
            const SizedBox(height: 12),
            Text(l10n.debtPaidPercent(dash.overallPaidOffPercentage.toStringAsFixed(0))),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: (dash.overallPaidOffPercentage / 100).clamp(0, 1)),
            if (dash.nextDueDate != null) ...[
              const SizedBox(height: 12),
              Text(
                l10n.nextLoanDue(
                  dash.nextDueLoanName ?? '',
                  MoneyFormatter.format(dash.nextDueAmount, currency: currency, locale: locale),
                  DateFormatter.short(dash.nextDueDate!, locale),
                ),
              ),
            ],
            if (dash.debtDistribution.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(l10n.debtDistribution, style: context.texts.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 28,
                    sections: [
                      for (var i = 0; i < dash.debtDistribution.length; i++)
                        PieChartSectionData(
                          value: dash.debtDistribution[i].balance <= 0 ? 0.01 : dash.debtDistribution[i].balance,
                          title: '${dash.debtDistribution[i].percentage.toStringAsFixed(0)}%',
                          radius: 42,
                          color: Colors.primaries[i % Colors.primaries.length],
                        ),
                    ],
                  ),
                ),
              ),
              ...dash.debtDistribution.map(
                (d) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(d.name),
                  trailing: Text(MoneyFormatter.format(d.balance, currency: currency, locale: locale)),
                ),
              ),
            ],
            if (dash.debtEvolution.length >= 2) ...[
              const SizedBox(height: 8),
              Text(l10n.debtEvolution, style: context.texts.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SizedBox(
                height: 140,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        barWidth: 3,
                        color: Theme.of(context).colorScheme.primary,
                        spots: [
                          for (var i = 0; i < dash.debtEvolution.length; i++)
                            FlSpot(i.toDouble(), dash.debtEvolution[i].balance),
                        ],
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${l10n.capitalVsInterest}: ${MoneyFormatter.format(dash.totalCapitalPaid, currency: currency, locale: locale)} / ${MoneyFormatter.format(dash.totalInterestComponent, currency: currency, locale: locale)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value, style: context.texts.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _LoanListTile extends StatelessWidget {
  const _LoanListTile({required this.loan, required this.currency, required this.locale});
  final Loan loan;
  final String currency;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => context.push('/loans/${loan.id}'),
        leading: CircleAvatar(
          backgroundColor: context.colors.primary.withValues(alpha: 0.12),
          child: Icon(Icons.account_balance, color: context.colors.primary),
        ),
        title: Text(loan.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${loanTypeLabel(l10n, loan.loanType)} · ${loan.creditor}\n'
          '${l10n.balance}: ${MoneyFormatter.format(loan.currentBalance, currency: currency, locale: locale)}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class LoanFormScreen extends ConsumerStatefulWidget {
  const LoanFormScreen({super.key, this.id});
  final String? id;

  @override
  ConsumerState<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends ConsumerState<LoanFormScreen> {
  final _name = TextEditingController();
  final _creditor = TextEditingController();
  final _principal = TextEditingController();
  final _rate = TextEditingController(text: '15');
  final _term = TextEditingController(text: '48');
  final _fees = TextEditingController(text: '0');
  final _notes = TextEditingController();
  final _account = TextEditingController();
  final _currentBalance = TextEditingController();
  final _remaining = TextEditingController();
  final _customPayment = TextEditingController();
  final _penaltyRate = TextEditingController(text: '0');
  final _penaltyFixed = TextEditingController(text: '0');

  String _loanType = 'PERSONAL';
  String _frequency = 'MONTHLY';
  String _amortization = 'FRENCH';
  String _currency = 'DOP';
  bool _existing = false;
  bool _saving = false;
  DateTime _disbursement = DateTime.now();
  DateTime _firstDue = DateTime.now().add(const Duration(days: 30));
  DateTime? _nextDue;
  String? _categoryId;
  AmortizationSchedule? _preview;

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      Future.microtask(_loadExisting);
    }
  }

  Future<void> _loadExisting() async {
    final loan = await ref.read(financeRepositoryProvider).loan(widget.id!);
    setState(() {
      _name.text = loan.name;
      _creditor.text = loan.creditor;
      _loanType = loan.loanType;
      _principal.text = loan.originalPrincipal.toStringAsFixed(2);
      _currency = loan.currency;
      _rate.text = loan.annualInterestRate.toString();
      _term.text = loan.termMonths.toString();
      _frequency = loan.paymentFrequency;
      _amortization = loan.amortizationType;
      _account.text = loan.associatedAccountLabel ?? '';
      _fees.text = loan.additionalFees.toStringAsFixed(2);
      _notes.text = loan.notes ?? '';
      _penaltyRate.text = loan.earlyPaymentPenaltyRate.toString();
      _penaltyFixed.text = loan.earlyPaymentPenaltyFixed.toStringAsFixed(2);
      _categoryId = loan.defaultCategoryId;
      _disbursement = loan.disbursementDate;
      _firstDue = loan.firstInstallmentDate;
      _customPayment.text = loan.periodicPayment.toStringAsFixed(2);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _creditor.dispose();
    _principal.dispose();
    _rate.dispose();
    _term.dispose();
    _fees.dispose();
    _notes.dispose();
    _account.dispose();
    _currentBalance.dispose();
    _remaining.dispose();
    _customPayment.dispose();
    _penaltyRate.dispose();
    _penaltyFixed.dispose();
    super.dispose();
  }

  Future<void> _previewSchedule() async {
    final principal = double.tryParse(_principal.text.replaceAll(',', '.'));
    final rate = double.tryParse(_rate.text.replaceAll(',', '.'));
    final term = int.tryParse(_term.text);
    if (principal == null || rate == null || term == null) {
      return;
    }
    final schedule = await ref.read(financeRepositoryProvider).calculateLoan({
      'principal': _existing ? (double.tryParse(_currentBalance.text.replaceAll(',', '.')) ?? principal) : principal,
      'annualInterestRate': rate,
      'termMonths': _existing ? (int.tryParse(_remaining.text) ?? term) : term,
      'paymentFrequency': _frequency,
      'amortizationType': _amortization,
      'firstInstallmentDate': (_existing ? (_nextDue ?? _firstDue) : _firstDue).toUtc().toIso8601String(),
      'additionalFees': double.tryParse(_fees.text.replaceAll(',', '.')) ?? 0,
      if (_amortization == 'CUSTOM') 'customPeriodicPayment': double.tryParse(_customPayment.text.replaceAll(',', '.')),
    });
    setState(() => _preview = schedule);
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final principal = double.tryParse(_principal.text.replaceAll(',', '.'));
    final rate = double.tryParse(_rate.text.replaceAll(',', '.'));
    final term = int.tryParse(_term.text);
    if (_name.text.trim().isEmpty || _creditor.text.trim().isEmpty || principal == null || rate == null || term == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.completeRequiredFields)));
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.id == null) {
        await ref.read(financeRepositoryProvider).createLoan({
          'name': _name.text.trim(),
          'creditor': _creditor.text.trim(),
          'loanType': _loanType,
          'originalPrincipal': principal,
          'currency': _currency,
          'annualInterestRate': rate,
          'disbursementDate': _disbursement.toUtc().toIso8601String(),
          'firstInstallmentDate': _firstDue.toUtc().toIso8601String(),
          'termMonths': term,
          'paymentFrequency': _frequency,
          'amortizationType': _amortization,
          'associatedAccountLabel': _account.text.trim().isEmpty ? null : _account.text.trim(),
          'additionalFees': double.tryParse(_fees.text.replaceAll(',', '.')) ?? 0,
          'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          'earlyPaymentPenaltyRate': double.tryParse(_penaltyRate.text.replaceAll(',', '.')) ?? 0,
          'earlyPaymentPenaltyFixed': double.tryParse(_penaltyFixed.text.replaceAll(',', '.')) ?? 0,
          'defaultCategoryId': _categoryId,
          'isExistingLoan': _existing,
          if (_existing) 'currentBalance': double.tryParse(_currentBalance.text.replaceAll(',', '.')),
          if (_existing) 'remainingInstallments': int.tryParse(_remaining.text),
          if (_existing && _nextDue != null) 'nextPaymentDate': _nextDue!.toUtc().toIso8601String(),
          if (_amortization == 'CUSTOM') 'customPeriodicPayment': double.tryParse(_customPayment.text.replaceAll(',', '.')),
          'reminderDays': const [7, 3, 1, 0],
          'remindOnOverdue': true,
        });
      } else {
        await ref.read(financeRepositoryProvider).updateLoan(widget.id!, {
          'name': _name.text.trim(),
          'creditor': _creditor.text.trim(),
          'loanType': _loanType,
          'annualInterestRate': rate,
          'associatedAccountLabel': _account.text.trim().isEmpty ? null : _account.text.trim(),
          'additionalFees': double.tryParse(_fees.text.replaceAll(',', '.')) ?? 0,
          'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          'earlyPaymentPenaltyRate': double.tryParse(_penaltyRate.text.replaceAll(',', '.')) ?? 0,
          'earlyPaymentPenaltyFixed': double.tryParse(_penaltyFixed.text.replaceAll(',', '.')) ?? 0,
          'defaultCategoryId': _categoryId,
          'reminderDays': const [7, 3, 1, 0],
          'remindOnOverdue': true,
          'recalculateFutureSchedule': true,
          if (_amortization == 'CUSTOM') 'customPeriodicPayment': double.tryParse(_customPayment.text.replaceAll(',', '.')),
        });
      }
      ref.invalidate(loansProvider);
      ref.invalidate(loanDashboardProvider);
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapErrorCode(l10n, e))));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final expenseCategories = categories.where((c) => c.type == 'EXPENSE').toList();
    final currency = ref.watch(currencyProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.id == null ? l10n.newLoan : l10n.editLoan)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.id == null)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.existingLoan),
              subtitle: Text(l10n.existingLoanHint),
              value: _existing,
              onChanged: (v) => setState(() => _existing = v),
            ),
          TextField(controller: _name, decoration: InputDecoration(labelText: l10n.loanName)),
          const SizedBox(height: 12),
          TextField(controller: _creditor, decoration: InputDecoration(labelText: l10n.creditor)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _loanType,
            decoration: InputDecoration(labelText: l10n.loanType),
            items: [
              for (final t in const ['PERSONAL', 'MORTGAGE', 'VEHICLE', 'COMMERCIAL', 'CREDIT_CARD', 'OTHER'])
                DropdownMenuItem(value: t, child: Text(loanTypeLabel(l10n, t))),
            ],
            onChanged: (v) => setState(() => _loanType = v ?? _loanType),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _principal,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.originalPrincipal),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _currency,
            decoration: InputDecoration(labelText: l10n.currency),
            items: const [
              DropdownMenuItem(value: 'DOP', child: Text('DOP')),
              DropdownMenuItem(value: 'USD', child: Text('USD')),
              DropdownMenuItem(value: 'EUR', child: Text('EUR')),
            ],
            onChanged: (v) => setState(() => _currency = v ?? _currency),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.annualInterestRate),
          ),
          const SizedBox(height: 12),
          TextField(controller: _term, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.termMonths)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _frequency,
            decoration: InputDecoration(labelText: l10n.paymentFrequency),
            items: [
              for (final f in const ['WEEKLY', 'BIWEEKLY', 'MONTHLY'])
                DropdownMenuItem(value: f, child: Text(loanFrequencyLabel(l10n, f))),
            ],
            onChanged: (v) => setState(() => _frequency = v ?? _frequency),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _amortization,
            decoration: InputDecoration(labelText: l10n.amortizationType),
            items: [
              for (final a in const ['FRENCH', 'GERMAN', 'CUSTOM'])
                DropdownMenuItem(value: a, child: Text(amortizationLabel(l10n, a))),
            ],
            onChanged: (v) => setState(() => _amortization = v ?? _amortization),
          ),
          if (_amortization == 'CUSTOM') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customPayment,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.customInstallment),
            ),
          ],
          const SizedBox(height: 12),
          TextField(controller: _account, decoration: InputDecoration(labelText: l10n.associatedAccount)),
          const SizedBox(height: 12),
          TextField(
            controller: _fees,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.additionalFees),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.disbursementDate),
            subtitle: Text(DateFormatter.short(_disbursement, locale)),
            trailing: const Icon(Icons.event),
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: _disbursement, firstDate: DateTime(2000), lastDate: DateTime(2100));
              if (picked != null) {
                setState(() => _disbursement = picked);
              }
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.firstInstallmentDate),
            subtitle: Text(DateFormatter.short(_firstDue, locale)),
            trailing: const Icon(Icons.event),
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: _firstDue, firstDate: DateTime(2000), lastDate: DateTime(2100));
              if (picked != null) {
                setState(() => _firstDue = picked);
              }
            },
          ),
          if (_existing) ...[
            TextField(
              controller: _currentBalance,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.currentBalance),
            ),
            const SizedBox(height: 12),
            TextField(controller: _remaining, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.remainingInstallments)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.nextPaymentDate),
              subtitle: Text(_nextDue == null ? l10n.optional : DateFormatter.short(_nextDue!, locale)),
              trailing: const Icon(Icons.event),
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: _nextDue ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (picked != null) {
                  setState(() => _nextDue = picked);
                }
              },
            ),
          ],
          DropdownButtonFormField<String>(
            value: _categoryId ?? '',
            decoration: InputDecoration(labelText: l10n.defaultPaymentCategory),
            items: [
              DropdownMenuItem(value: '', child: Text(l10n.optional)),
              for (final c in expenseCategories)
                DropdownMenuItem(value: c.id, child: Text(categoryLabel(l10n, c.name, c.isDefault))),
            ],
            onChanged: (v) => setState(() => _categoryId = (v == null || v.isEmpty) ? null : v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _penaltyRate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.earlyPenaltyRate),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _penaltyFixed,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.earlyPenaltyFixed),
          ),
          const SizedBox(height: 12),
          TextField(controller: _notes, maxLines: 3, decoration: InputDecoration(labelText: l10n.notes)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _previewSchedule,
            icon: const Icon(Icons.preview_outlined),
            label: Text(l10n.previewAmortization),
          ),
          if (_preview != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${l10n.estimatedInstallment}: ${MoneyFormatter.format(_preview!.periodicPayment, currency: currency, locale: locale)}'),
                    Text('${l10n.totalInterest}: ${MoneyFormatter.format(_preview!.totalInterest, currency: currency, locale: locale)}'),
                    Text('${l10n.totalToPay}: ${MoneyFormatter.format(_preview!.totalPayment, currency: currency, locale: locale)}'),
                    Text('${l10n.estimatedEnd}: ${DateFormatter.short(_preview!.estimatedEndDate, locale)}'),
                    if (_preview!.isEstimate) Text(l10n.estimateDisclaimer, style: context.texts.bodySmall),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
