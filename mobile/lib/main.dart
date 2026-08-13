import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fintrack/app.dart';
import 'package:fintrack/core/notifications/notification_service.dart';
import 'package:fintrack/core/storage/prefs_storage.dart';
import 'package:fintrack/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FinTrackApp(),
    ),
  );

  _initNotifications(container, prefs);
}

Future<void> _initNotifications(ProviderContainer container, SharedPreferences prefs) async {
  try {
    final notifications = container.read(notificationServiceProvider);
    await notifications.init().timeout(const Duration(seconds: 3));
    final language = prefs.getString('locale') ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final locale = language == 'en' ? const Locale('en') : const Locale('es');
    await notifications.scheduleDailyReminder(lookupAppLocalizations(locale));
  } catch (_) {
    // Notifications must never block startup.
  }
}
