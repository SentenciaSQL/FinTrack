import 'package:flutter/material.dart';
import 'package:fintrack/core/extensions/context_extensions.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/utils/formatters.dart';

class AmountText extends StatelessWidget {
  const AmountText({
    super.key,
    required this.amount,
    required this.currency,
    required this.locale,
    this.isIncome,
    this.style,
  });

  final num amount;
  final String currency;
  final Locale locale;
  final bool? isIncome;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final color = isIncome == null
        ? null
        : (isIncome! ? AppColors.income : AppColors.expense);
    final text = isIncome == null
        ? MoneyFormatter.format(amount, currency: currency, locale: locale)
        : MoneyFormatter.signed(amount, currency: currency, locale: locale, isIncome: isIncome!);
    return Text(
      text,
      style: (style ?? context.texts.titleMedium)?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.color});

  final double value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final clamped = (value / 100).clamp(0.0, 1.2);
    final resolved = color ??
        (value >= 100
            ? AppColors.expense
            : value >= 80
                ? AppColors.warning
                : AppColors.income);
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: clamped > 1 ? 1 : clamped,
        minHeight: 8,
        color: resolved,
        backgroundColor: resolved.withValues(alpha: 0.15),
      ),
    );
  }
}
