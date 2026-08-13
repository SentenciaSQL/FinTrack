import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fintrack/core/constants/app_config.dart';
import 'package:fintrack/core/errors/error_mapper.dart';
import 'package:fintrack/core/extensions/context_extensions.dart';
import 'package:fintrack/core/localization/locale_provider.dart';
import 'package:fintrack/core/theme/theme_provider.dart';
import 'package:fintrack/core/utils/formatters.dart';
import 'package:fintrack/core/widgets/money.dart';
import 'package:fintrack/core/widgets/states.dart';
import 'package:fintrack/features/auth/data/auth_repository.dart';
import 'package:fintrack/features/dashboard/data/finance_repository.dart';
import 'package:fintrack/features/dashboard/presentation/providers.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreOptions)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          _tile(context, Icons.person_outline, l10n.profile, () => context.push('/profile')),
          _tile(context, Icons.category_outlined, l10n.categories, () => context.push('/categories')),
          _tile(context, Icons.flag_outlined, l10n.savingsGoals, () => context.push('/savings')),
          _tile(context, Icons.autorenew, l10n.recurring, () => context.push('/recurring')),
          _tile(context, Icons.settings_outlined, l10n.settings, () => context.push('/settings')),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(leading: Icon(icon), title: Text(title), trailing: const Icon(Icons.chevron_right), onTap: onTap),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = ref.watch(localeProvider);
    final theme = ref.watch(themeModeProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.languageAndRegion, style: context.texts.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(l10n.language),
                  subtitle: Text(locale.languageCode == 'en' ? l10n.english : l10n.spanish),
                ),
                RadioListTile<String>(
                  value: 'es',
                  groupValue: locale.languageCode,
                  title: Text(l10n.spanish),
                  onChanged: (_) => ref.read(localeProvider.notifier).setLocale(const Locale('es')),
                ),
                RadioListTile<String>(
                  value: 'en',
                  groupValue: locale.languageCode,
                  title: Text(l10n.english),
                  onChanged: (_) => ref.read(localeProvider.notifier).setLocale(const Locale('en')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.appearance, style: context.texts.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(value: ThemeMode.light, groupValue: theme, title: Text(l10n.light), onChanged: (v) => ref.read(themeModeProvider.notifier).setMode(v!)),
                RadioListTile<ThemeMode>(value: ThemeMode.dark, groupValue: theme, title: Text(l10n.dark), onChanged: (v) => ref.read(themeModeProvider.notifier).setMode(v!)),
                RadioListTile<ThemeMode>(value: ThemeMode.system, groupValue: theme, title: Text(l10n.system), onChanged: (v) => ref.read(themeModeProvider.notifier).setMode(v!)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.currency, style: context.texts.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (final code in ['DOP', 'USD', 'EUR'])
                  RadioListTile<String>(
                    value: code,
                    groupValue: currency,
                    title: Text(code),
                    onChanged: (value) async {
                      await ref.read(currencyProvider.notifier).setCurrency(value!);
                      final user = ref.read(authControllerProvider).valueOrNull?.user;
                      if (user != null) {
                        await ref.read(authRepositoryProvider).updateProfile(
                              name: user.name,
                              preferredLanguage: locale.languageCode,
                              preferredCurrency: value,
                            );
                      }
                    },
                  ),
              ],
            ),
          ),
          if (kDebugMode || AppConfig.isDevelopment) ...[
            const SizedBox(height: 16),
            Text(l10n.developer, style: context.texts.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () async {
                try {
                  await ref.read(financeRepositoryProvider).loadDemoData();
                  ref.invalidate(dashboardProvider);
                  ref.invalidate(transactionsProvider);
                  ref.invalidate(budgetsProvider);
                  ref.invalidate(goalsProvider);
                  ref.invalidate(recurringProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.demoDataLoaded)));
                  }
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapErrorCode(l10n, error))));
                  }
                }
              },
              child: Text(l10n.loadDemoData),
            ),
          ],
          const SizedBox(height: 24),
          Text(l10n.about, style: context.texts.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(l10n.aboutBody),
          const SizedBox(height: 8),
          Text(l10n.version, style: context.texts.bodySmall),
        ],
      ),
    );
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _current = TextEditingController();
  final _next = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    _name.text = user?.name ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(authControllerProvider).valueOrNull?.user;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.account, style: context.texts.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextField(controller: _name, decoration: InputDecoration(labelText: l10n.name)),
          const SizedBox(height: 12),
          TextFormField(initialValue: user?.email ?? '', enabled: false, decoration: InputDecoration(labelText: l10n.email)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await ref.read(authRepositoryProvider).updateProfile(
                    name: _name.text.trim(),
                    preferredLanguage: ref.read(localeProvider).languageCode,
                    preferredCurrency: ref.read(currencyProvider),
                  );
              await ref.read(authControllerProvider.notifier).refreshProfile();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.profileUpdated)));
              }
            },
            child: Text(l10n.save),
          ),
          const SizedBox(height: 24),
          Text(l10n.security, style: context.texts.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextField(controller: _current, obscureText: true, decoration: InputDecoration(labelText: l10n.currentPassword)),
          const SizedBox(height: 12),
          TextField(controller: _next, obscureText: true, decoration: InputDecoration(labelText: l10n.newPassword)),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () async {
              try {
                await ref.read(authRepositoryProvider).changePassword(currentPassword: _current.text, newPassword: _next.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.passwordChanged)));
                }
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapErrorCode(l10n, error))));
                }
              }
            },
            child: Text(l10n.changePassword),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.logoutConfirmTitle),
                  content: Text(l10n.logoutConfirmBody),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.logout)),
                  ],
                ),
              );
              if (ok == true) {
                await ref.read(authControllerProvider.notifier).logout();
              }
            },
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categories),
        actions: [
          IconButton(
            onPressed: () => _create(context, ref),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => FtErrorState(message: mapErrorCode(l10n, error), onRetry: () => ref.invalidate(categoriesProvider)),
        data: (items) => ListView(
          padding: const EdgeInsets.all(16),
          children: items
              .map(
                (c) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(categoryIcon(c.icon, c.type)),
                    title: Text(categoryLabel(l10n, c.name, c.isDefault)),
                    subtitle: Text(transactionTypeLabel(l10n, c.type)),
                    trailing: c.isDefault
                        ? Chip(label: Text(l10n.defaultCategory))
                        : IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await ref.read(financeRepositoryProvider).deleteCategory(c.id);
                              ref.invalidate(categoriesProvider);
                            },
                          ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final name = TextEditingController();
    var type = 'EXPENSE';
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: InputDecoration(labelText: l10n.name)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: type,
                items: [
                  DropdownMenuItem(value: 'EXPENSE', child: Text(l10n.expense)),
                  DropdownMenuItem(value: 'INCOME', child: Text(l10n.income)),
                ],
                onChanged: (value) => type = value ?? 'EXPENSE',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await ref.read(financeRepositoryProvider).createCategory(name: name.text.trim(), type: type);
                  ref.invalidate(categoriesProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
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

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(goalsProvider);
    final currency = ref.watch(currencyProvider);
    final locale = ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.savingsGoals),
        actions: [IconButton(onPressed: () => _create(context, ref), icon: const Icon(Icons.add))],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => FtErrorState(message: mapErrorCode(l10n, error), onRetry: () => ref.invalidate(goalsProvider)),
        data: (items) {
          if (items.isEmpty) {
            return FtEmptyState(icon: Icons.flag_outlined, title: l10n.emptyGoals, subtitle: l10n.emptyGoalsHint, actionLabel: l10n.newGoal, onAction: () => _create(context, ref));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final goal = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.name, style: context.texts.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      _row(l10n.target, MoneyFormatter.format(goal.targetAmount, currency: currency, locale: locale)),
                      _row(l10n.saved, MoneyFormatter.format(goal.currentAmount, currency: currency, locale: locale)),
                      const SizedBox(height: 8),
                      ProgressBar(value: goal.progressPercentage),
                      const SizedBox(height: 8),
                      Text(l10n.percentUsed(goal.progressPercentage.toStringAsFixed(0))),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _contribute(context, ref, goal.id),
                          child: Text(l10n.contribute),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [Expanded(child: Text(label)), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))]),
      );

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final name = TextEditingController();
    final amount = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: InputDecoration(labelText: l10n.name)),
            const SizedBox(height: 12),
            TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: l10n.targetAmount)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final parsed = double.tryParse(amount.text.replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) {
                  return;
                }
                await ref.read(financeRepositoryProvider).saveGoal(name: name.text.trim(), targetAmount: parsed);
                ref.invalidate(goalsProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _contribute(BuildContext context, WidgetRef ref, String id) async {
    final l10n = context.l10n;
    final amount = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: l10n.amount)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final parsed = double.tryParse(amount.text.replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) {
                  return;
                }
                await ref.read(financeRepositoryProvider).addContribution(id, parsed, DateTime.now());
                ref.invalidate(goalsProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text(l10n.addContribution),
            ),
          ],
        ),
      ),
    );
  }
}

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(recurringProvider);
    final currency = ref.watch(currencyProvider);
    final locale = ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recurring),
        actions: [IconButton(onPressed: () => _create(context, ref), icon: const Icon(Icons.add))],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => FtErrorState(message: mapErrorCode(l10n, error), onRetry: () => ref.invalidate(recurringProvider)),
        data: (items) {
          if (items.isEmpty) {
            return FtEmptyState(icon: Icons.autorenew, title: l10n.emptyRecurring, subtitle: l10n.emptyRecurringHint, actionLabel: l10n.newRecurring, onAction: () => _create(context, ref));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(item.description),
                  subtitle: Text('${frequencyLabel(l10n, item.frequency)} · ${DateFormatter.short(item.nextExecutionDate, locale)}'),
                  trailing: AmountText(amount: item.amount, currency: currency, locale: locale, isIncome: item.type == 'INCOME', style: context.texts.bodyLarge),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final categories = await ref.read(categoriesProvider.future);
    if (!context.mounted) {
      return;
    }
    final description = TextEditingController();
    final amount = TextEditingController();
    var type = 'EXPENSE';
    var frequency = 'MONTHLY';
    String? categoryId = categories.where((c) => c.type == type).firstOrNull?.id;
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
              TextField(controller: description, decoration: InputDecoration(labelText: l10n.description)),
              const SizedBox(height: 12),
              TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: l10n.amount)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: type,
                items: [
                  DropdownMenuItem(value: 'EXPENSE', child: Text(l10n.expense)),
                  DropdownMenuItem(value: 'INCOME', child: Text(l10n.income)),
                ],
                onChanged: (value) => type = value ?? 'EXPENSE',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: categoryId,
                items: categories.where((c) => c.type == type).map((c) => DropdownMenuItem(value: c.id, child: Text(categoryLabel(l10n, c.name, c.isDefault)))).toList(),
                onChanged: (value) => categoryId = value,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: frequency,
                items: [
                  DropdownMenuItem(value: 'WEEKLY', child: Text(l10n.weekly)),
                  DropdownMenuItem(value: 'BIWEEKLY', child: Text(l10n.biweekly)),
                  DropdownMenuItem(value: 'MONTHLY', child: Text(l10n.monthly)),
                  DropdownMenuItem(value: 'YEARLY', child: Text(l10n.yearly)),
                ],
                onChanged: (value) => frequency = value ?? 'MONTHLY',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final parsed = double.tryParse(amount.text.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0 || categoryId == null) {
                    return;
                  }
                  await ref.read(financeRepositoryProvider).saveRecurring(
                        type: type,
                        amount: parsed,
                        description: description.text.trim(),
                        categoryId: categoryId!,
                        frequency: frequency,
                        nextExecutionDate: DateTime.now().add(const Duration(days: 30)),
                        active: true,
                      );
                  ref.invalidate(recurringProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
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
