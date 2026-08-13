import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:fintrack/core/models/models.dart';
import 'package:fintrack/l10n/app_localizations.dart';
import 'package:fintrack/core/utils/formatters.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  var _ready = false;

  Future<void> init() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  Future<void> scheduleDailyReminder(AppLocalizations l10n) async {
    if (!_ready) {
      return;
    }
    await _plugin.zonedSchedule(
      1,
      l10n.dailyReminderTitle,
      l10n.dailyReminderBody,
      _next(20, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails('daily', 'Daily reminders', importance: Importance.defaultImportance),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> syncAlerts({
    required AppLocalizations l10n,
    required List<Budget> budgets,
    required List<SavingsGoal> goals,
    required List<RecurringTransaction> recurring,
  }) async {
    if (!_ready) {
      return;
    }

    var id = 10;
    for (final budget in budgets) {
      final name = categoryLabel(l10n, budget.categoryName, budget.categoryIsDefault);
      if (budget.usedPercentage >= 100) {
        await _show(id++, l10n.budgetExceededTitle, l10n.budgetExceededBody(name));
      } else if (budget.usedPercentage >= 80) {
        await _show(id++, l10n.budgetWarningTitle, l10n.budgetWarningBody(name));
      }
    }

    for (final goal in goals) {
      if (goal.progressPercentage >= 80 && goal.progressPercentage < 100) {
        await _show(id++, l10n.goalAlmostTitle, l10n.goalAlmostBody(goal.name));
      }
    }

    final soon = DateTime.now().add(const Duration(days: 3));
    for (final item in recurring.where((e) => e.active && e.nextExecutionDate.isBefore(soon))) {
      await _show(id++, l10n.recurringSoonTitle, l10n.recurringSoonBody(item.description));
    }
  }

  Future<void> _show(int id, String title, String body) {
    return _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails('alerts', 'FinTrack alerts', importance: Importance.high),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  tz.TZDateTime _next(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
