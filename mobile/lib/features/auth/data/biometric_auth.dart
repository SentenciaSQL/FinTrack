import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:fintrack/core/constants/storage_keys.dart';
import 'package:fintrack/core/storage/prefs_storage.dart';

abstract class BiometricGateway {
  Future<bool> get isAvailable;
  Future<bool> authenticate(String reason);
}

class LocalBiometricGateway implements BiometricGateway {
  LocalBiometricGateway([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> get isAvailable async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!supported && !canCheck) {
        return false;
      }
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}

final biometricGatewayProvider = Provider<BiometricGateway>((ref) => LocalBiometricGateway());

final biometricAvailableProvider = FutureProvider<bool>((ref) {
  return ref.watch(biometricGatewayProvider).isAvailable;
});

final biometricEnabledProvider = NotifierProvider<BiometricEnabledNotifier, bool>(BiometricEnabledNotifier.new);

class BiometricEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(sharedPreferencesProvider).getBool(StorageKeys.biometricUnlock) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    if (value) {
      ref.read(biometricLockProvider.notifier).unlock();
    }
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(StorageKeys.biometricUnlock, value);
  }
}

/// While this instant is in the future, returning from the system prompt
/// must not lock the app again.
final biometricResumeGuardProvider = StateProvider<DateTime?>((ref) => null);

final biometricLockProvider = NotifierProvider<BiometricLockNotifier, bool>(BiometricLockNotifier.new);

class BiometricLockNotifier extends Notifier<bool> {
  var _holdUnlocked = false;

  @override
  bool build() {
    final enabled = ref.watch(biometricEnabledProvider);
    if (!enabled || _holdUnlocked) {
      return false;
    }
    return true;
  }

  void unlock() {
    _holdUnlocked = true;
    state = false;
  }

  void lock() {
    _holdUnlocked = false;
    state = ref.read(biometricEnabledProvider);
  }
}

final biometricActionsProvider = Provider<BiometricActions>((ref) => BiometricActions(ref));

class BiometricActions {
  BiometricActions(this._ref);

  final Ref _ref;

  Future<bool> authenticate(String reason) async {
    _ref.read(biometricResumeGuardProvider.notifier).state = DateTime.now().add(const Duration(seconds: 8));
    try {
      return await _ref.read(biometricGatewayProvider).authenticate(reason);
    } finally {
      _ref.read(biometricResumeGuardProvider.notifier).state = DateTime.now().add(const Duration(seconds: 1));
    }
  }
}
