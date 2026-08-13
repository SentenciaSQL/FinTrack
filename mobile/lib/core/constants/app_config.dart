import 'dart:io';

class AppConfig {
  AppConfig._();

  static const flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'development',
  );

  static const _overrideUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_overrideUrl.isNotEmpty) {
      return _overrideUrl;
    }

    switch (flavor) {
      case 'production':
        return 'https://api.fintrack.app/api';
      case 'staging':
        return 'https://staging.api.fintrack.app/api';
      default:
        if (Platform.isAndroid) {
          return 'http://10.0.2.2:8080/api';
        }
        return 'http://localhost:8080/api';
    }
  }

  static bool get isDevelopment => flavor == 'development';
}
