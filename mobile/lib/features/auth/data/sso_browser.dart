import 'package:flutter/services.dart';

const _channel = MethodChannel('flutter_web_auth_2');
const ssoCallbackScheme = 'fintrack';

/// Opens the identity provider in the system browser and waits for
/// `fintrack://sso/callback`.
///
/// The plugin's public `FlutterWebAuth2` type is not referenced here. Its
/// library re-exports a file that imports the library again, and the Dart
/// analyzer then reports that type as undefined.
Future<String> openSsoBrowser(String url) async {
  final result = await _channel.invokeMethod<String>('authenticate', {
    'url': url,
    'callbackUrlScheme': ssoCallbackScheme,
    'options': const {
      'preferEphemeral': false,
      'intentFlags': 0,
      'timeout': 300,
      'silentAuth': false,
      'useWebview': true,
    },
  });
  if (result == null || result.isEmpty) {
    throw PlatformException(code: 'CANCELED');
  }
  return result;
}
