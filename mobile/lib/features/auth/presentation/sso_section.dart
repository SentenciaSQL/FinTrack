import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/core/errors/error_mapper.dart';
import 'package:fintrack/core/extensions/context_extensions.dart';
import 'package:fintrack/features/auth/data/auth_repository.dart';
import 'package:fintrack/l10n/app_localizations.dart';
import 'package:fintrack/routing/return_path.dart';

class SsoSignInSection extends ConsumerWidget {
  const SsoSignInSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providers = ref.watch(ssoProvidersProvider);
    final busyId = ref.watch(ssoFlowProvider).busyProviderId;
    final passwordBusy = ref.watch(authControllerProvider).isLoading;

    return providers.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        final l10n = context.l10n;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final provider in items) ...[
              _ProviderButton(
                provider: provider,
                label: _providerLabel(l10n, provider),
                busy: busyId == provider.id,
                enabled: busyId == null && !passwordBusy,
                onPressed: () => _start(context, ref, provider),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    l10n.orDivider,
                    style: context.texts.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Future<void> _start(
    BuildContext context,
    WidgetRef ref,
    SsoProvider provider,
  ) async {
    try {
      final result = await ref
          .read(ssoFlowProvider.notifier)
          .start(
            provider: provider.id,
            intent: 'sign_in',
            returnPath: ref.read(returnPathProvider),
          );
      if (result is SsoLinkRequired && context.mounted) {
        await showSsoLinkDialog(context, result);
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mapErrorCode(l10n, error)),
          action: SnackBarAction(
            label: l10n.retry,
            onPressed: () => _start(context, ref, provider),
          ),
        ),
      );
    }
  }
}

class SignInMethodsSection extends ConsumerStatefulWidget {
  const SignInMethodsSection({super.key});

  @override
  ConsumerState<SignInMethodsSection> createState() =>
      _SignInMethodsSectionState();
}

class _SignInMethodsSectionState extends ConsumerState<SignInMethodsSection> {
  final _current = TextEditingController();
  final _next = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final methods = ref.watch(authMethodsProvider);
    final busyId = ref.watch(ssoFlowProvider).busyProviderId;

    return methods.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.authMethodsLoadError),
          TextButton(
            onPressed: () => ref.invalidate(authMethodsProvider),
            child: Text(l10n.retry),
          ),
        ],
      ),
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.signInMethods,
            style: context.texts.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.password_outlined),
                  title: Text(l10n.passwordMethod),
                  subtitle: Text(
                    data.hasPassword ? l10n.passwordSet : l10n.passwordMissing,
                  ),
                ),
                const Divider(height: 1),
                for (final method in data.methods)
                  ListTile(
                    leading: _ProviderMark(id: method.provider),
                    title: Text(method.displayName),
                    subtitle: Text(
                      method.email == null || method.email!.isEmpty
                          ? l10n.connected
                          : method.email!,
                    ),
                    trailing: TextButton(
                      onPressed: busyId == null
                          ? () => _disconnect(method)
                          : null,
                      child: Text(l10n.disconnect),
                    ),
                  ),
                for (final provider in data.availableProviders)
                  if (!data.methods.any((method) => method.provider == provider.id))
                    ListTile(
                      leading: _ProviderMark(id: provider.id),
                      title: Text(provider.displayName),
                      trailing: busyId == provider.id
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton(
                              onPressed: busyId == null
                                  ? () => _connect(provider)
                                  : null,
                              child: Text(l10n.connect),
                            ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (data.hasPassword) ...[
            TextField(
              controller: _current,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.currentPassword),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _next,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.newPassword),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _changePassword,
              child: Text(l10n.changePassword),
            ),
          ] else ...[
            Text(
              l10n.passwordNotSet,
              style: context.texts.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _next,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.newPassword),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _setPassword,
              child: Text(l10n.setPassword),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _connect(SsoProvider provider) async {
    try {
      final result = await ref
          .read(ssoFlowProvider.notifier)
          .start(
            provider: provider.id,
            intent: 'link',
            returnPath: '/profile',
          );
      if (!mounted) {
        return;
      }
      if (result is SsoLinked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.providerConnected(result.providerDisplayName),
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mapErrorCode(l10n, error)),
          action: SnackBarAction(
            label: l10n.retry,
            onPressed: () => _connect(provider),
          ),
        ),
      );
    }
  }

  Future<void> _disconnect(LinkedAuthMethod method) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.disconnectTitle(method.displayName)),
        content: Text(l10n.disconnectBody(method.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.disconnect),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await ref.read(authRepositoryProvider).unlinkProvider(method.provider);
      ref.invalidate(authMethodsProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.providerDisconnected(method.displayName))),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapErrorCode(l10n, error))),
      );
    }
  }

  Future<void> _changePassword() async {
    final l10n = context.l10n;
    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      _current.clear();
      _next.clear();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.passwordChanged)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapErrorCode(l10n, error))));
    }
  }

  Future<void> _setPassword() async {
    final l10n = context.l10n;
    try {
      await ref.read(authRepositoryProvider).setInitialPassword(_next.text);
      _next.clear();
      ref.invalidate(authMethodsProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.passwordChanged)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapErrorCode(l10n, error))));
    }
  }
}

Future<void> showSsoLinkDialog(
  BuildContext context,
  SsoLinkRequired link,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => _LinkAccountDialog(link: link),
  );
}

class _LinkAccountDialog extends ConsumerStatefulWidget {
  const _LinkAccountDialog({required this.link});

  final SsoLinkRequired link;

  @override
  ConsumerState<_LinkAccountDialog> createState() => _LinkAccountDialogState();
}

class _LinkAccountDialogState extends ConsumerState<_LinkAccountDialog> {
  final _password = TextEditingController();
  var _busy = false;
  var _obscure = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final providerName = widget.link.providerDisplayName.isEmpty
        ? widget.link.provider
        : widget.link.providerDisplayName;
    return AlertDialog(
      title: Text(l10n.linkAccountTitle),
      content: widget.link.canUsePassword
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.linkAccountBody(widget.link.email, providerName)),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    errorText: _error,
                    suffixIcon: IconButton(
                      tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Text(l10n.ssoLinkUnavailable),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        if (widget.link.canUsePassword)
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.linkAccountAction),
          ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_password.text.isEmpty) {
      return;
    }
    setState(() => _busy = true);
    try {
      final completion = await ref
          .read(authRepositoryProvider)
          .linkWithPassword(
            linkToken: widget.link.linkToken,
            password: _password.text,
          );
      final back = sanitizeReturnPath(
        completion.returnPath ?? widget.link.returnPath,
      );
      if (back != null) {
        ref.read(returnPathProvider.notifier).remember(back);
      }
      await ref.read(authControllerProvider.notifier).adopt(completion.auth);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = mapErrorCode(context.l10n, error);
      });
    }
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.provider,
    required this.label,
    required this.busy,
    required this.enabled,
    required this.onPressed,
  });

  final SsoProvider provider;
  final String label;
  final bool busy;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Semantics(
      button: true,
      label: label,
      child: OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        foregroundColor: scheme.onSurface,
        backgroundColor: scheme.surface,
        side: BorderSide(color: scheme.outline),
      ),
      child: busy
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.primary,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ExcludeSemantics(child: _ProviderMark(id: provider.id)),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

class _ProviderMark extends StatelessWidget {
  const _ProviderMark({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return switch (id) {
      'google' => const _GoogleMark(),
      'microsoft' => const _MicrosoftMark(),
      _ => Icon(Icons.account_circle_outlined, color: context.colors.primary),
    };
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final stroke = size.width * 0.18;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - stroke / 2,
    );
    const colors = [
      Color(0xFF4285F4),
      Color(0xFF34A853),
      Color(0xFFFBBC05),
      Color(0xFFEA4335),
    ];
    const sweeps = [1.2, 1.15, 1.2, 1.7];
    var start = -0.4;
    for (var index = 0; index < colors.length; index++) {
      final paint = Paint()
        ..color = colors[index]
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweeps[index], false, paint);
      start += sweeps[index];
    }
    final bar = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.48,
        size.height * 0.42,
        size.width * 0.46,
        stroke,
      ),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MicrosoftMark extends StatelessWidget {
  const _MicrosoftMark();

  @override
  Widget build(BuildContext context) {
    Widget square(Color color) => Container(
      width: 8,
      height: 8,
      color: color,
    );
    return SizedBox(
      width: 20,
      height: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              square(const Color(0xFFF25022)),
              const SizedBox(width: 2),
              square(const Color(0xFF7FBA00)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              square(const Color(0xFF00A4EF)),
              const SizedBox(width: 2),
              square(const Color(0xFFFFB900)),
            ],
          ),
        ],
      ),
    );
  }
}

String _providerLabel(AppLocalizations l10n, SsoProvider provider) {
  return switch (provider.id) {
    'google' => l10n.continueWithGoogle,
    'microsoft' => l10n.continueWithMicrosoft,
    _ => l10n.continueWithProvider(provider.displayName),
  };
}
