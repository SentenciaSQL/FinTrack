import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fintrack/core/errors/error_mapper.dart';
import 'package:fintrack/core/extensions/context_extensions.dart';
import 'package:fintrack/core/localization/locale_provider.dart';
import 'package:fintrack/features/auth/data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapErrorCode(l10n, error))));
        },
      );
    });

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset('assets/branding/app_icon.png', width: 56, height: 56),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.login, style: context.texts.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(l10n.loginSubtitle, style: context.texts.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant)),
            const SizedBox(height: 32),
            Form(
              key: _form,
              child: Column(
                children: [
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: l10n.email, prefixIcon: const Icon(Icons.mail_outline)),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.requiredField;
                      }
                      if (!value.contains('@')) {
                        return l10n.invalidEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty ? l10n.requiredField : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: auth.isLoading ? null : _submit,
              child: auth.isLoading ? const CircularProgressIndicator() : Text(l10n.signIn),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.noAccount),
                TextButton(onPressed: () => context.go('/register'), child: Text(l10n.register)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    await ref.read(authControllerProvider.notifier).login(_email.text.trim(), _password.text);
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapErrorCode(l10n, error))));
        },
      );
    });

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l10n.register, style: context.texts.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(l10n.registerSubtitle, style: context.texts.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant)),
          const SizedBox(height: 32),
          Form(
            key: _form,
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: l10n.name, prefixIcon: const Icon(Icons.person_outline)),
                  validator: (value) => value == null || value.trim().isEmpty ? l10n.requiredField : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l10n.email, prefixIcon: const Icon(Icons.mail_outline)),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.requiredField;
                    }
                    if (!value.contains('@')) {
                      return l10n.invalidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l10n.password, prefixIcon: const Icon(Icons.lock_outline)),
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return l10n.passwordMin;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: auth.isLoading ? null : _submit,
            child: auth.isLoading ? const CircularProgressIndicator() : Text(l10n.createAccount),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.hasAccount),
              TextButton(onPressed: () => context.go('/login'), child: Text(l10n.login)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    await ref.read(authControllerProvider.notifier).register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          language: ref.read(localeProvider).languageCode,
        );
  }
}
