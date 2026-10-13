import 'dart:io';

import 'package:flutter/services.dart';

class AppConfig {
  AppConfig._();

  static const flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'development',
  );

  static const _overrideUrl = String.fromEnvironment('API_BASE_URL');
  static const _emulatorApi = 'http://10.0.2.2:8080/api';
  static const _usbDeviceApi = 'http://127.0.0.1:8080/api';

  static String? _developmentBaseUrl;

  static String get apiBaseUrl {
    if (_overrideUrl.isNotEmpty) {
      return _overrideUrl;
    }
    if (_developmentBaseUrl != null) {
      return _developmentBaseUrl!;
    }

    switch (flavor) {
      case 'production':
        return 'https://api.fintrack.app/api';
      case 'staging':
        return 'https://staging.api.fintrack.app/api';
      default:
        if (Platform.isAndroid) {
          return _emulatorApi;
        }
        return 'http://localhost:8080/api';
    }
  }

  /// A physical Android phone cannot use the emulator address `10.0.2.2`.
  /// USB debugging reaches the computer through `127.0.0.1` after
  /// `adb reverse tcp:8080 tcp:8080`.
  static Future<void> prepareDevelopmentHost() async {
    if (_overrideUrl.isNotEmpty ||
        flavor != 'development' ||
        !Platform.isAndroid) {
      return;
    }
    try {
      const channel = MethodChannel('fintrack/device');
      final emulator = await channel.invokeMethod<bool>('isEmulator');
      if (emulator == false) {
        _developmentBaseUrl = _usbDeviceApi;
      }
    } catch (_) {
      // The provider request still tries both Android loopback addresses.
    }
  }

  static List<String> developmentApiCandidates(String current) {
    if (_overrideUrl.isNotEmpty ||
        flavor != 'development' ||
        !Platform.isAndroid) {
      return [current];
    }
    return [
      current,
      if (current != _usbDeviceApi) _usbDeviceApi,
      if (current != _emulatorApi) _emulatorApi,
    ];
  }

  static bool get isDevelopment => flavor == 'development';
}
