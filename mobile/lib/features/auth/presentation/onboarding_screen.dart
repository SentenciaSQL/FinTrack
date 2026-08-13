import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fintrack/core/constants/storage_keys.dart';
import 'package:fintrack/core/extensions/context_extensions.dart';
import 'package:fintrack/core/storage/prefs_storage.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  var _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = [
      (Icons.insights_rounded, l10n.onboardingTitle1, l10n.onboardingBody1),
      (Icons.pie_chart_rounded, l10n.onboardingTitle2, l10n.onboardingBody2),
      (Icons.flag_rounded, l10n.onboardingTitle3, l10n.onboardingBody3),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _finish(context),
                  child: Text(l10n.skip),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, i) {
                    final page = pages[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page.$1, size: 64, color: context.colors.primary),
                        ),
                        const SizedBox(height: 32),
                        Text(page.$2, textAlign: TextAlign.center, style: context.texts.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        Text(page.$3, textAlign: TextAlign.center, style: context.texts.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant)),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _index == i ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _index == i ? context.colors.primary : context.colors.outlineVariant,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (_index == pages.length - 1) {
                    _finish(context);
                  } else {
                    _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                  }
                },
                child: Text(_index == pages.length - 1 ? l10n.getStarted : l10n.next),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finish(BuildContext context) async {
    final container = ProviderScope.containerOf(context);
    await container.read(sharedPreferencesProvider).setBool(StorageKeys.onboardingComplete, true);
    if (context.mounted) {
      context.go('/login');
    }
  }
}
