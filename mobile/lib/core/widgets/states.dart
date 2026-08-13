import 'package:flutter/material.dart';
import 'package:fintrack/core/extensions/context_extensions.dart';

class FtEmptyState extends StatelessWidget {
  const FtEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: context.colors.primary),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: context.texts.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: context.texts.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class FtErrorState extends StatelessWidget {
  const FtErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FtEmptyState(
      icon: Icons.error_outline_rounded,
      title: context.l10n.errorGeneric,
      subtitle: message,
      actionLabel: context.l10n.retry,
      onAction: onRetry,
    );
  }
}

class FtSkeleton extends StatelessWidget {
  const FtSkeleton({super.key, this.height = 88});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class FtSectionHeader extends StatelessWidget {
  const FtSectionHeader({super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: context.texts.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}
