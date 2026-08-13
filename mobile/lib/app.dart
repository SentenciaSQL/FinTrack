import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/core/localization/locale_provider.dart';
import 'package:fintrack/core/notifications/notification_service.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/theme/theme_provider.dart';
import 'package:fintrack/l10n/app_localizations.dart';
import 'package:fintrack/routing/app_router.dart';

class FinTrackApp extends ConsumerWidget {
  const FinTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    ref.listen(localeProvider, (previous, next) {
      final l10n = lookupAppLocalizations(next);
      ref.read(notificationServiceProvider).scheduleDailyReminder(l10n);
    });

    return MaterialApp.router(
      title: 'FinTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }
}
