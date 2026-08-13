import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/core/constants/storage_keys.dart';
import 'package:fintrack/core/storage/prefs_storage.dart';

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(StorageKeys.locale);
    if (stored == 'en' || stored == 'es') {
      return Locale(stored!);
    }

    final device = WidgetsBinding.instance.platformDispatcher.locale;
    if (device.languageCode == 'en') {
      return const Locale('en');
    }
    return const Locale('es');
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await ref.read(sharedPreferencesProvider).setString(StorageKeys.locale, locale.languageCode);
  }
}
