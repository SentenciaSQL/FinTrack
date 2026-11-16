import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/core/extensions/context_extensions.dart';
import 'package:fintrack/core/localization/locale_provider.dart';
import 'package:fintrack/core/models/models.dart';
import 'package:fintrack/core/theme/theme_provider.dart';
import 'package:fintrack/core/utils/formatters.dart';
import 'package:fintrack/features/dashboard/data/finance_repository.dart';

class LoanCalculatorScreen extends ConsumerStatefulWidget {
  const LoanCalculatorScreen({super.key});

  @override
  ConsumerState<LoanCalculatorScreen> createState() => _LoanCalculatorScreenState();
}

class _LoanCalculatorScreenState extends ConsumerState<LoanCalculatorScreen> {
  final _principal = TextEditingController(text: '500000');
  final _rate = TextEditingController(text: '15');
  final _term = TextEditingController(text: '48');
  final _fees = TextEditingController(text: '0');
  final _custom = TextEditingController();
  String _frequency = 'MONTHLY';
  String _amortization = 'FRENCH';
  DateTime _firstDue = DateTime.now().add(const Duration(days: 30));
  AmortizationSchedule? _schedule;
  bool _busy = false;

  @override
  void dispose() {
    _principal.dispose();
    _rate.dispose();
    _term.dispose();
    _fees.dispose();
    _custom.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    final principal = double.tryParse(_principal.text.replaceAll(',', '.'));
    final rate = double.tryParse(_rate.text.replaceAll(',', '.'));
    final term = int.tryParse(_term.text);
    if (principal == null || rate == null || term == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await ref.read(financeRepositoryProvider).calculateLoan({
        'principal': principal,
        'annualInterestRate': rate,
        'termMonths': term,
        'paymentFrequency': _frequency,
        'amortizationType': _amortization,
        'firstInstallmentDate': _firstDue.toUtc().toIso8601String(),
        'additionalFees': double.tryParse(_fees.text.replaceAll(',', '.')) ?? 0,
        if (_amortization == 'CUSTOM') 'customPeriodicPayment': double.tryParse(_custom.text.replaceAll(',', '.')),
      });
      setState(() => _schedule = result);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = ref.watch(currencyProvider);
    final locale = ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.loanCalculator)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _principal,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.originalPrincipal),
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
              controller: _custom,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.customInstallment),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _fees,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.additionalFees),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.firstInstallmentDate),
            subtitle: Text(DateFormatter.short(_firstDue, locale)),
            trailing: const Icon(Icons.event),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _firstDue,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _firstDue = picked);
              }
            },
          ),
          FilledButton(onPressed: _busy ? null : _calculate, child: Text(l10n.calculate)),
          if (_schedule != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${l10n.estimatedInstallment}: ${MoneyFormatter.format(_schedule!.periodicPayment, currency: currency, locale: locale)}'),
                    Text('${l10n.totalInterest}: ${MoneyFormatter.format(_schedule!.totalInterest, currency: currency, locale: locale)}'),
                    Text('${l10n.totalToPay}: ${MoneyFormatter.format(_schedule!.totalPayment, currency: currency, locale: locale)}'),
                    Text('${l10n.estimatedEnd}: ${DateFormatter.short(_schedule!.estimatedEndDate, locale)}'),
                    if (_schedule!.isEstimate) Text(l10n.estimateDisclaimer, style: context.texts.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.amortizationTable, style: context.texts.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ..._schedule!.rows.map(
              (row) => ListTile(
                dense: true,
                title: Text('#${row.number} · ${DateFormatter.short(row.dueDate, locale)}'),
                subtitle: Text(
                  '${l10n.capital}: ${MoneyFormatter.format(row.principal, currency: currency, locale: locale)} · '
                  '${l10n.interest}: ${MoneyFormatter.format(row.interest, currency: currency, locale: locale)}',
                ),
                trailing: Text(MoneyFormatter.format(row.payment, currency: currency, locale: locale)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
