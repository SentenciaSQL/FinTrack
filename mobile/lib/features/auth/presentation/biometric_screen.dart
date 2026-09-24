import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/core/constants/storage_keys.dart';
import 'package:fintrack/core/extensions/context_extensions.dart';
import 'package:fintrack/core/storage/prefs_storage.dart';
import 'package:fintrack/features/auth/data/auth_repository.dart';
import 'package:fintrack/features/auth/data/biometric_auth.dart';

class BiometricCoordinator extends ConsumerStatefulWidget {
  const BiometricCoordinator({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<BiometricCoordinator> createState() => _BiometricCoordinatorState();
}

class _BiometricCoordinatorState extends ConsumerState<BiometricCoordinator> with WidgetsBindingObserver {
  var _wasPaused = false;
  var _offering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasPaused = true;
    }
    if (state == AppLifecycleState.resumed && _wasPaused) {
      _wasPaused = false;
      final until = ref.read(biometricResumeGuardProvider);
      if (until != null && DateTime.now().isBefore(until)) {
        return;
      }
      final signedIn = ref.read(authControllerProvider).valueOrNull?.isAuthenticated == true;
      if (signedIn && ref.read(biometricEnabledProvider)) {
        ref.read(biometricLockProvider.notifier).lock();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      final wasIn = previous?.valueOrNull?.isAuthenticated == true;
      final nowIn = next.valueOrNull?.isAuthenticated == true;
      if (!wasIn && nowIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _offerFingerprint());
      }
    });
    return widget.child;
  }

  Future<void> _offerFingerprint() async {
    if (!mounted || _offering) {
      return;
    }
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs.getBool(StorageKeys.biometricOfferSeen) == true || ref.read(biometricEnabledProvider)) {
      return;
    }
    final available = await ref.read(biometricGatewayProvider).isAvailable;
    if (!available || !mounted) {
      return;
    }
    _offering = true;
    final l10n = context.l10n;
    final enable = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.biometricOfferTitle),
        content: Text(l10n.biometricOfferBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.biometricNotNow)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.biometricEnable)),
        ],
      ),
    );
    await prefs.setBool(StorageKeys.biometricOfferSeen, true);
    if (enable == true && mounted) {
      final ok = await ref.read(biometricActionsProvider).authenticate(l10n.biometricUnlockBody);
      if (ok) {
        await ref.read(biometricEnabledProvider.notifier).setEnabled(true);
      }
    }
    _offering = false;
  }
}

class BiometricSettingsTile extends ConsumerWidget {
  const BiometricSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final enabled = ref.watch(biometricEnabledProvider);
    final available = ref.watch(biometricAvailableProvider);

    return available.when(
      loading: () => SwitchListTile(
        secondary: const Icon(Icons.fingerprint),
        title: Text(l10n.biometricTitle),
        subtitle: Text(l10n.biometricSubtitle),
        value: enabled,
        onChanged: null,
      ),
      error: (_, _) => SwitchListTile(
        secondary: const Icon(Icons.fingerprint),
        title: Text(l10n.biometricTitle),
        subtitle: Text(l10n.biometricUnavailable),
        value: false,
        onChanged: null,
      ),
      data: (supported) => SwitchListTile(
        secondary: const Icon(Icons.fingerprint),
        title: Text(l10n.biometricTitle),
        subtitle: Text(supported ? l10n.biometricSubtitle : l10n.biometricUnavailable),
        value: enabled && supported,
        onChanged: supported
            ? (value) async {
                if (value) {
                  final ok = await ref.read(biometricActionsProvider).authenticate(l10n.biometricUnlockBody);
                  if (!ok) {
                    return;
                  }
                }
                await ref.read(biometricEnabledProvider.notifier).setEnabled(value);
              }
            : null,
      ),
    );
  }
}

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  var _failed = false;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _failed = false;
    });
    final ok = await ref.read(biometricActionsProvider).authenticate(context.l10n.biometricUnlockBody);
    if (!mounted) {
      return;
    }
    if (ok) {
      ref.read(biometricLockProvider.notifier).unlock();
      return;
    }
    setState(() {
      _busy = false;
      _failed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.fingerprint, size: 88, color: context.colors.primary),
              const SizedBox(height: 24),
              Text(l10n.biometricUnlockTitle, style: context.texts.headlineSmall?.copyWith(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                _failed ? l10n.biometricFailed : l10n.biometricUnlockBody,
                style: context.texts.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _busy ? null : _unlock,
                icon: const Icon(Icons.fingerprint),
                label: Text(l10n.biometricUnlockAction),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy
                    ? null
                    : () async {
                        await ref.read(authControllerProvider.notifier).logout();
                      },
                child: Text(l10n.biometricUsePassword),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
