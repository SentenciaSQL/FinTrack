import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/core/constants/storage_keys.dart';
import 'package:fintrack/core/storage/prefs_storage.dart';

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final preferences = ref.watch(sharedPreferencesProvider);

    final storedLanguage = preferences.getString(StorageKeys.locale);

    if (storedLanguage == 'en' || storedLanguage == 'es') {
      return Locale(storedLanguage!);
    }

    return const Locale('es');
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode != 'es' && locale.languageCode != 'en') {
      return;
    }

    state = locale;

    await ref
        .read(sharedPreferencesProvider)
        .setString(StorageKeys.locale, locale.languageCode);
  }
}
