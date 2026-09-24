import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fintrack/core/constants/storage_keys.dart';
import 'package:fintrack/core/storage/prefs_storage.dart';
import 'package:fintrack/features/auth/data/biometric_auth.dart';
import 'package:fintrack/features/auth/presentation/biometric_screen.dart';
import 'package:fintrack/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a saved fingerprint preference locks the session until it is confirmed', () async {
    SharedPreferences.setMockInitialValues({StorageKeys.biometricUnlock: true});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(container.read(biometricLockProvider), isTrue);
    container.read(biometricLockProvider.notifier).unlock();
    expect(container.read(biometricLockProvider), isFalse);
    container.read(biometricLockProvider.notifier).lock();
    expect(container.read(biometricLockProvider), isTrue);
  });

  testWidgets('confirming the fingerprint unlocks the app', (tester) async {
    SharedPreferences.setMockInitialValues({StorageKeys.biometricUnlock: true});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        biometricGatewayProvider.overrideWithValue(_AcceptingGateway()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: UnlockScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(container.read(biometricLockProvider), isFalse);
  });
}

class _AcceptingGateway implements BiometricGateway {
  @override
  Future<bool> get isAvailable async => true;

  @override
  Future<bool> authenticate(String reason) async => true;
}
