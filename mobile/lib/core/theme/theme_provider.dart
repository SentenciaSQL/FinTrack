import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/core/constants/storage_keys.dart';
import 'package:fintrack/core/storage/prefs_storage.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final value = ref.watch(sharedPreferencesProvider).getString(StorageKeys.themeMode);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await ref.read(sharedPreferencesProvider).setString(StorageKeys.themeMode, value);
  }
}

final currencyProvider = NotifierProvider<CurrencyNotifier, String>(CurrencyNotifier.new);

class CurrencyNotifier extends Notifier<String> {
  @override
  String build() {
    return ref.watch(sharedPreferencesProvider).getString(StorageKeys.currency) ?? 'DOP';
  }

  Future<void> setCurrency(String currency) async {
    state = currency;
    await ref.read(sharedPreferencesProvider).setString(StorageKeys.currency, currency);
  }
}
