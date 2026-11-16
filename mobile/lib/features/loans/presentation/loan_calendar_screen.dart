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
import 'package:fintrack/features/dashboard/presentation/providers.dart';

class LoanCalendarScreen extends ConsumerStatefulWidget {
  const LoanCalendarScreen({super.key});

  @override
  ConsumerState<LoanCalendarScreen> createState() => _LoanCalendarScreenState();
}

class _LoanCalendarScreenState extends ConsumerState<LoanCalendarScreen> {
  DateTime _focused = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(loanCalendarProvider);
    final currency = ref.watch(currencyProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.loanCalendar)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => FtErrorState(message: mapErrorCode(l10n, e), onRetry: () => ref.invalidate(loanCalendarProvider)),
        data: (items) {
          final byDay = <DateTime, List<LoanCalendarItem>>{};
          for (final item in items) {
            final key = DateTime(item.dueDate.year, item.dueDate.month, item.dueDate.day);
            byDay.putIfAbsent(key, () => []).add(item);
          }
          final selectedKey = _selected == null ? null : DateTime(_selected!.year, _selected!.month, _selected!.day);
          final selectedItems = selectedKey == null ? const <LoanCalendarItem>[] : (byDay[selectedKey] ?? const <LoanCalendarItem>[]);
          final upcoming = items.where((e) => e.status != 'PAID').take(20).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _focused = DateTime(_focused.year, _focused.month - 1)),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      DateFormatter.monthYear(_focused.month, _focused.year, locale),
                      textAlign: TextAlign.center,
                      style: context.texts.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _focused = DateTime(_focused.year, _focused.month + 1)),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _MonthGrid(
                month: _focused,
                markedDays: byDay,
                selected: _selected,
                onSelect: (day) => setState(() => _selected = day),
              ),
              const SizedBox(height: 16),
              Text(l10n.selectedDayPayments, style: context.texts.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (_selected == null)
                Text(l10n.selectCalendarDay)
              else if (selectedItems.isEmpty)
                Text(l10n.noPaymentsOnDay)
              else
                ...selectedItems.map((item) => _CalendarTile(item: item, currency: currency, locale: locale)),
              const SizedBox(height: 20),
              Text(l10n.upcomingPayments, style: context.texts.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (upcoming.isEmpty)
                FtEmptyState(icon: Icons.event_available, title: l10n.noUpcomingPayments, subtitle: '')
              else
                ...upcoming.map((item) => _CalendarTile(item: item, currency: currency, locale: locale)),
            ],
          );
        },
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.markedDays,
    required this.selected,
    required this.onSelect,
  });

  final DateTime month;
  final Map<DateTime, List<LoanCalendarItem>> markedDays;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startWeekday = first.weekday % 7;
    final cells = <Widget>[
      for (final label in const ['D', 'L', 'M', 'X', 'J', 'V', 'S'])
        Center(child: Text(label, style: context.texts.labelSmall?.copyWith(fontWeight: FontWeight.w700))),
      for (var i = 0; i < startWeekday; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        Builder(
          builder: (context) {
            final date = DateTime(month.year, month.month, day);
            final marks = markedDays[date] ?? const <LoanCalendarItem>[];
            final isSelected = selected != null && selected!.year == date.year && selected!.month == date.month && selected!.day == date.day;
            Color? dot;
            if (marks.any((m) => m.status == 'OVERDUE')) {
              dot = context.colors.error;
            } else if (marks.any((m) => m.status == 'PAID')) {
              dot = Colors.green;
            } else if (marks.isNotEmpty) {
              dot = context.colors.primary;
            }
            return InkWell(
              onTap: () => onSelect(date),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? context.colors.primary.withValues(alpha: 0.15) : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$day'),
                    if (dot != null) Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                  ],
                ),
              ),
            );
          },
        ),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }
}

class _CalendarTile extends StatelessWidget {
  const _CalendarTile({required this.item, required this.currency, required this.locale});
  final LoanCalendarItem item;
  final String currency;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: ListTile(
        onTap: () => context.push('/loans/${item.loanId}'),
        title: Text(item.loanName),
        subtitle: Text(
          '${DateFormatter.short(item.dueDate, locale)} · ${installmentStatusLabel(l10n, item.status)}'
          '${item.installmentNumber == null ? '' : ' · #${item.installmentNumber}'}',
        ),
        trailing: Text(
          MoneyFormatter.format(item.remainingAmount > 0 ? item.remainingAmount : item.amount, currency: currency, locale: locale),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
