import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fintrack/core/errors/error_mapper.dart';
import 'package:fintrack/core/extensions/context_extensions.dart';
import 'package:fintrack/core/localization/locale_provider.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/theme/theme_provider.dart';
import 'package:fintrack/core/utils/formatters.dart';
import 'package:fintrack/core/widgets/money.dart';
import 'package:fintrack/core/widgets/states.dart';
import 'package:fintrack/features/dashboard/data/finance_repository.dart';
import 'package:fintrack/features/dashboard/presentation/providers.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final query = ref.watch(transactionQueryProvider);
    final async = ref.watch(transactionsProvider);
    final currency = ref.watch(currencyProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transactions)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: l10n.search,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    _search.clear();
                    ref.read(transactionQueryProvider.notifier).state = query.copyWith(search: '');
                  },
                  icon: const Icon(Icons.close),
                ),
              ),
              onSubmitted: (value) {
                ref.read(transactionQueryProvider.notifier).state = query.copyWith(search: value);
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(l10n.all),
                  selected: query.type == null,
                  onSelected: (_) => ref.read(transactionQueryProvider.notifier).state = query.copyWith(clearType: true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(l10n.income),
                  selected: query.type == 'INCOME',
                  onSelected: (_) => ref.read(transactionQueryProvider.notifier).state = query.copyWith(type: 'INCOME'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(l10n.expenses),
                  selected: query.type == 'EXPENSE',
                  onSelected: (_) => ref.read(transactionQueryProvider.notifier).state = query.copyWith(type: 'EXPENSE'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: async.when(
              loading: () => const Padding(padding: EdgeInsets.all(16), child: FtSkeleton(height: 320)),
              error: (error, _) => FtErrorState(message: mapErrorCode(l10n, error), onRetry: () => ref.invalidate(transactionsProvider)),
              data: (page) {
                if (page.items.isEmpty) {
                  return FtEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: l10n.emptyTransactions,
                    subtitle: l10n.emptyTransactionsHint,
                    actionLabel: l10n.addExpense,
                    onAction: () => context.push('/transactions/new?type=EXPENSE'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(transactionsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    itemCount: page.items.length,
                    itemBuilder: (context, index) {
                      final tx = page.items[index];
                      final income = tx.type == 'INCOME';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () => context.push('/transactions/${tx.id}'),
                          leading: CircleAvatar(
                            backgroundColor: (income ? AppColors.income : AppColors.expense).withValues(alpha: 0.12),
                            child: Icon(categoryIcon(tx.categoryIcon, tx.type), color: income ? AppColors.income : AppColors.expense),
                          ),
                          title: Text(tx.description),
                          subtitle: Text('${categoryLabel(l10n, tx.categoryName, tx.categoryIsDefault)} · ${DateFormatter.short(tx.date, locale)}'),
                          trailing: AmountText(amount: tx.amount, currency: currency, locale: locale, isIncome: income, style: context.texts.bodyLarge),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(transactionProvider(id));
    final l10n = context.l10n;
    final currency = ref.watch(currencyProvider);
    final locale = ref.watch(localeProvider);

    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(appBar: AppBar(), body: FtErrorState(message: mapErrorCode(l10n, error), onRetry: () => ref.invalidate(transactionProvider(id)))),
      data: (tx) {
        final income = tx.type == 'INCOME';
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.transactionDetails),
            actions: [
              IconButton(onPressed: () => context.push('/transactions/$id/edit'), icon: const Icon(Icons.edit_outlined)),
              IconButton(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.deleteConfirmTitle),
                      content: Text(l10n.deleteConfirmBody),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await ref.read(financeRepositoryProvider).deleteTransaction(id);
                    ref.invalidate(transactionsProvider);
                    ref.invalidate(dashboardProvider);
                    if (context.mounted) {
                      context.pop();
                    }
                  }
                },
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      AmountText(amount: tx.amount, currency: currency, locale: locale, isIncome: income, style: context.texts.headlineMedium),
                      const SizedBox(height: 8),
                      Text(tx.description, style: context.texts.titleMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(title: Text(l10n.type), trailing: Text(transactionTypeLabel(l10n, tx.type))),
              ListTile(title: Text(l10n.category), trailing: Text(categoryLabel(l10n, tx.categoryName, tx.categoryIsDefault))),
              ListTile(title: Text(l10n.date), trailing: Text(DateFormatter.long(tx.date, locale))),
              ListTile(title: Text(l10n.paymentMethod), trailing: Text(paymentMethodLabel(l10n, tx.paymentMethod))),
              if (tx.notes != null) ListTile(title: Text(l10n.notes), subtitle: Text(tx.notes!)),
            ],
          ),
        );
      },
    );
  }
}

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key, this.id, this.initialType});
  final String? id;
  final String? initialType;

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _form = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  late String _type;
  String _payment = 'CASH';
  String? _categoryId;
  DateTime _date = DateTime.now();
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? 'EXPENSE';
    if (widget.id != null) {
      Future.microtask(_load);
    }
  }

  Future<void> _load() async {
    final tx = await ref.read(financeRepositoryProvider).transaction(widget.id!);
    setState(() {
      _type = tx.type;
      _payment = tx.paymentMethod;
      _categoryId = tx.categoryId;
      _date = tx.date.toLocal();
      _description.text = tx.description;
      _amount.text = tx.amount.toString();
      _notes.text = tx.notes ?? '';
    });
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final filtered = categories.where((c) => c.type == _type).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.id == null ? l10n.newTransaction : l10n.editTransaction)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'EXPENSE', label: Text(l10n.expense)),
                ButtonSegment(value: 'INCOME', label: Text(l10n.income)),
              ],
              selected: {_type},
              onSelectionChanged: (value) => setState(() {
                _type = value.first;
                _categoryId = null;
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.amount),
              validator: (value) {
                final parsed = double.tryParse(value ?? '');
                if (parsed == null || parsed <= 0) {
                  return l10n.amountGreaterThanZero;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              decoration: InputDecoration(labelText: l10n.description),
              maxLength: 200,
              validator: (value) => value == null || value.trim().isEmpty ? l10n.requiredField : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: filtered.any((c) => c.id == _categoryId) ? _categoryId : null,
              decoration: InputDecoration(labelText: l10n.category),
              items: filtered
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(categoryLabel(l10n, c.name, c.isDefault))))
                  .toList(),
              onChanged: (value) => setState(() => _categoryId = value),
              validator: (value) => value == null ? l10n.categoryRequired : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _payment,
              decoration: InputDecoration(labelText: l10n.paymentMethod),
              items: [
                DropdownMenuItem(value: 'CASH', child: Text(l10n.cash)),
                DropdownMenuItem(value: 'DEBIT_CARD', child: Text(l10n.debitCard)),
                DropdownMenuItem(value: 'CREDIT_CARD', child: Text(l10n.creditCard)),
                DropdownMenuItem(value: 'BANK_TRANSFER', child: Text(l10n.bankTransfer)),
                DropdownMenuItem(value: 'OTHER', child: Text(l10n.other)),
              ],
              onChanged: (value) => setState(() => _payment = value ?? 'CASH'),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.date),
              subtitle: Text(DateFormatter.long(_date, ref.watch(localeProvider))),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _date = picked);
                }
              },
            ),
            TextFormField(controller: _notes, decoration: InputDecoration(labelText: '${l10n.notes} (${l10n.optional})'), maxLines: 3),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading ? const CircularProgressIndicator() : Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(financeRepositoryProvider).saveTransaction(
            id: widget.id,
            type: _type,
            amount: double.parse(_amount.text.replaceAll(',', '.')),
            description: _description.text.trim(),
            date: _date,
            categoryId: _categoryId!,
            paymentMethod: _payment,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          );
      ref.invalidate(transactionsProvider);
      ref.invalidate(dashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.savedSuccessfully)));
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapErrorCode(context.l10n, error))));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}
