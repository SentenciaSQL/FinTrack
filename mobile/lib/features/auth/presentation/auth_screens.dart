import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSessionNotice());
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _showSessionNotice() {
    if (!mounted || !ref.read(sessionNoticeProvider)) {
      return;
    }
    ref.read(sessionNoticeProvider.notifier).dismiss();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.errUnauthorized)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = ref.watch(authControllerProvider);
    final locale = ref.watch(localeProvider);
    ref.listen(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapErrorCode(l10n, error))));
        },
      );
    });
    ref.listen<bool>(sessionNoticeProvider, (previous, next) {
      if (next) {
        _showSessionNotice();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _LanguageSwitch(
              locale: locale,
              onSelected: (language) => ref.read(localeProvider.notifier).setLocale(Locale(language)),
            ),
            const SizedBox(height: 8),
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
              child: AutofillGroup(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username, AutofillHints.email],
                      enableSuggestions: false,
                      autocorrect: false,
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
                    _PasswordField(
                      controller: _password,
                      label: l10n.password,
                      showLabel: l10n.showPassword,
                      hideLabel: l10n.hidePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (value) => value == null || value.isEmpty ? l10n.requiredField : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: auth.isLoading ? null : _submit,
              child: auth.isLoading ? const _ButtonSpinner() : Text(l10n.signIn),
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
    final form = _form.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    await ref.read(authControllerProvider.notifier).login(_email.text.trim(), _password.text);
    if (!mounted) {
      return;
    }
    if (ref.read(authControllerProvider).valueOrNull?.isAuthenticated == true) {
      TextInput.finishAutofillContext();
    }
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

    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _LanguageSwitch(
            locale: locale,
            onSelected: (language) => ref.read(localeProvider.notifier).setLocale(Locale(language)),
          ),
          Text(l10n.register, style: context.texts.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(l10n.registerSubtitle, style: context.texts.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant)),
          const SizedBox(height: 32),
          Form(
            key: _form,
            child: AutofillGroup(
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    decoration: InputDecoration(labelText: l10n.name, prefixIcon: const Icon(Icons.person_outline)),
                    validator: (value) => value == null || value.trim().isEmpty ? l10n.requiredField : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username, AutofillHints.email],
                    enableSuggestions: false,
                    autocorrect: false,
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
                  _PasswordField(
                    controller: _password,
                    label: l10n.password,
                    showLabel: l10n.showPassword,
                    hideLabel: l10n.hidePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
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
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: auth.isLoading ? null : _submit,
            child: auth.isLoading ? const _ButtonSpinner() : Text(l10n.createAccount),
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
    final form = _form.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    await ref.read(authControllerProvider.notifier).register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          language: ref.read(localeProvider).languageCode,
        );
    if (!mounted) {
      return;
    }
    if (ref.read(authControllerProvider).valueOrNull?.isAuthenticated == true) {
      TextInput.finishAutofillContext();
    }
  }
}

class _LanguageSwitch extends StatelessWidget {
  const _LanguageSwitch({required this.locale, required this.onSelected});

  final Locale locale;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Align(
      alignment: Alignment.centerRight,
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: 'es', label: Text(l10n.spanish)),
          ButtonSegment(value: 'en', label: Text(l10n.english)),
        ],
        selected: {locale.languageCode == 'en' ? 'en' : 'es'},
        onSelectionChanged: (value) => onSelected(value.first),
      ),
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.showLabel,
    required this.hideLabel,
    required this.validator,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String showLabel;
  final String hideLabel;
  final FormFieldValidator<String> validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  var _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      enableSuggestions: false,
      autocorrect: false,
      enableIMEPersonalizedLearning: false,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      autofillHints: const [AutofillHints.password],
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      enableInteractiveSelection: true,
      inputFormatters: const [_PasswordPasteFormatter()],
      onFieldSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _obscure ? widget.showLabel : widget.hideLabel,
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
        ),
      ),
      validator: widget.validator,
    );
  }
}

/// Strips control characters that a paste or password manager can insert.
///
/// A trailing newline or a composing range that no longer matches the text
/// has thrown inside the text field. Normal passwords, including symbols, pass through.
class _PasswordPasteFormatter extends TextInputFormatter {
  const _PasswordPasteFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final cleaned = newValue.text.replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), '');
    if (cleaned == newValue.text) {
      return newValue;
    }
    final rawOffset = newValue.selection.isValid ? newValue.selection.extentOffset : cleaned.length;
    final offset = rawOffset < 0 ? 0 : (rawOffset > cleaned.length ? cleaned.length : rawOffset);
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: offset),
      composing: TextRange.empty,
    );
  }
}
