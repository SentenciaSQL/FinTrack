import 'package:flutter/material.dart';
import 'package:fintrack/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class MoneyFormatter {
  MoneyFormatter._();

  static String format(num amount, {required String currency, required Locale locale}) {
    final symbol = switch (currency) {
      'USD' => r'US$',
      'EUR' => '€',
      _ => r'RD$',
    };
    final format = NumberFormat.currency(
      locale: locale.toString(),
      symbol: symbol,
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  static String signed(num amount, {required String currency, required Locale locale, required bool isIncome}) {
    final value = format(amount.abs(), currency: currency, locale: locale);
    return isIncome ? '+$value' : '-$value';
  }
}

class DateFormatter {
  DateFormatter._();

  static String long(DateTime date, Locale locale) {
    return DateFormat.yMMMMd(locale.toString()).format(date.toLocal());
  }

  static String short(DateTime date, Locale locale) {
    return DateFormat.yMMMd(locale.toString()).format(date.toLocal());
  }

  static String monthYear(int month, int year, Locale locale) {
    return DateFormat.yMMMM(locale.toString()).format(DateTime(year, month));
  }
}

String categoryLabel(AppLocalizations l10n, String name, bool isDefault) {
  if (!isDefault) {
    return name;
  }
  return switch (name) {
    'FOOD' => l10n.catFood,
    'TRANSPORTATION' => l10n.catTransportation,
    'HOUSING' => l10n.catHousing,
    'UTILITIES' => l10n.catUtilities,
    'HEALTH' => l10n.catHealth,
    'EDUCATION' => l10n.catEducation,
    'ENTERTAINMENT' => l10n.catEntertainment,
    'SHOPPING' => l10n.catShopping,
    'SUBSCRIPTIONS' => l10n.catSubscriptions,
    'TRAVEL' => l10n.catTravel,
    'SALARY' => l10n.catSalary,
    'FREELANCE' => l10n.catFreelance,
    'BUSINESS' => l10n.catBusiness,
    'INVESTMENTS' => l10n.catInvestments,
    'GIFTS' => l10n.catGifts,
    'OTHER' => l10n.catOther,
    _ => name,
  };
}

String paymentMethodLabel(AppLocalizations l10n, String method) {
  return switch (method) {
    'CASH' => l10n.cash,
    'DEBIT_CARD' => l10n.debitCard,
    'CREDIT_CARD' => l10n.creditCard,
    'BANK_TRANSFER' => l10n.bankTransfer,
    _ => l10n.other,
  };
}

String frequencyLabel(AppLocalizations l10n, String frequency) {
  return switch (frequency) {
    'WEEKLY' => l10n.weekly,
    'BIWEEKLY' => l10n.biweekly,
    'MONTHLY' => l10n.monthly,
    'YEARLY' => l10n.yearly,
    _ => frequency,
  };
}

String transactionTypeLabel(AppLocalizations l10n, String type) {
  return type == 'INCOME' ? l10n.income : l10n.expense;
}

IconData categoryIcon(String? icon, String type) {
  return switch (icon) {
    'restaurant' => Icons.restaurant_rounded,
    'directions_car' => Icons.directions_car_rounded,
    'home' => Icons.home_rounded,
    'bolt' => Icons.bolt_rounded,
    'favorite' => Icons.favorite_rounded,
    'school' => Icons.school_rounded,
    'movie' => Icons.movie_rounded,
    'shopping_bag' => Icons.shopping_bag_rounded,
    'subscriptions' => Icons.subscriptions_rounded,
    'flight' => Icons.flight_rounded,
    'payments' => Icons.payments_rounded,
    'laptop' => Icons.laptop_rounded,
    'storefront' => Icons.storefront_rounded,
    'trending_up' => Icons.trending_up_rounded,
    'card_giftcard' => Icons.card_giftcard_rounded,
    _ => type == 'INCOME' ? Icons.south_west_rounded : Icons.north_east_rounded,
  };
}
