import 'package:intl/intl.dart';

import 'currency.dart';
import 'money.dart';

/// Writes money the way the owner reads it: "$12,500.00", or "$12,500"
/// where cents would only add noise.
class MoneyFormatter {
  MoneyFormatter(this.currency);

  final Currency currency;

  static final _groupedDollars = NumberFormat('#,##0', 'en_US');

  String format(Money amount) => _write(amount, _dollarsAndCents);

  /// Drops the cents when they are zero; keeps them when they are not.
  String formatShort(Money amount) {
    final hasCents = amount.cents % Money.centsPerDollar != 0;
    return _write(amount, hasCents ? _dollarsAndCents : _dollarsOnly);
  }

  /// "+$20" or "−$20", for variances and movements.
  String formatSigned(Money amount) {
    if (amount.isZero) return formatShort(amount);
    final sign = amount.isNegative ? '−' : '+';
    return '$sign${formatShort(amount.abs())}';
  }

  /// Plain digits for an input field: "1200.50".
  String formatForEditing(Money amount) {
    final dollars = amount.cents ~/ Money.centsPerDollar;
    final cents = amount.cents % Money.centsPerDollar;
    return cents == 0 ? '$dollars' : '$dollars.${cents.toString().padLeft(2, '0')}';
  }

  String _write(Money amount, String Function(int cents) digitsOf) {
    final sign = amount.isNegative ? '−' : '';
    return '$sign${currency.symbol}${digitsOf(amount.abs().cents)}';
  }

  static String _dollarsOnly(int cents) =>
      _groupedDollars.format(cents ~/ Money.centsPerDollar);

  static String _dollarsAndCents(int cents) {
    final remainder = cents % Money.centsPerDollar;
    return '${_dollarsOnly(cents)}.${remainder.toString().padLeft(2, '0')}';
  }
}
