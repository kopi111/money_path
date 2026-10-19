import 'money.dart';

/// Reads an amount typed by a person ("1,200", "15000.5", "$3.25") into
/// exact cents without passing through floating point.
class MoneyParser {
  const MoneyParser();

  static final _allowed = RegExp(r'^\d+(\.\d{0,2})?$');

  Money parse(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\s,$J]'), '');
    if (!_allowed.hasMatch(cleaned)) {
      throw FormatException('Not an amount of money', input);
    }
    return Money.cents(_toCents(cleaned));
  }

  int _toCents(String cleaned) {
    final parts = cleaned.split('.');
    final dollars = int.parse(parts.first);
    final fraction = parts.length > 1 ? parts[1].padRight(2, '0') : '00';
    return dollars * Money.centsPerDollar + int.parse(fraction);
  }
}
