import 'package:flutter_test/flutter_test.dart';
import 'package:money_path/domain/money/currency.dart';
import 'package:money_path/domain/money/money.dart';
import 'package:money_path/domain/money/money_formatter.dart';
import 'package:money_path/domain/money/money_parser.dart';

void main() {
  group('Money', () {
    test('adds cents exactly where floating point would drift', () {
      final total = Money.sum(List.filled(10, const Money.cents(10)));
      expect(total, const Money.cents(100));
    });

    test('instalments round up so the instalments always reach the whole', () {
      final instalment = Money.dollars(1200).instalmentOf(52);
      expect(instalment, const Money.cents(2308));
      expect(instalment.times(52) >= Money.dollars(1200), isTrue);
    });

    test('an even split has no rounding', () {
      expect(Money.dollars(1200).instalmentOf(12), Money.dollars(100));
    });

    test('percent rounds down', () {
      expect(const Money.cents(99990).percentOf(Money.dollars(1000)), 99);
    });

    test('rejects splitting into zero parts', () {
      expect(() => Money.dollars(1).instalmentOf(0), throwsArgumentError);
    });
  });

  group('MoneyParser', () {
    const parser = MoneyParser();

    test('reads grouped dollars', () {
      expect(parser.parse('15,000'), Money.dollars(15000));
    });

    test('reads one decimal place as tens of cents', () {
      expect(parser.parse('12.5'), const Money.cents(1250));
    });

    test('ignores a leading dollar sign', () {
      expect(parser.parse(r'J$3.25'), const Money.cents(325));
    });

    test('refuses three decimal places', () {
      expect(() => parser.parse('1.005'), throwsFormatException);
    });

    test('refuses words', () {
      expect(() => parser.parse('ten'), throwsFormatException);
    });
  });

  group('MoneyFormatter', () {
    final formatter = MoneyFormatter(Currency.jamaicanDollar);

    test('groups thousands and keeps cents', () {
      expect(formatter.format(const Money.cents(1250050)), r'$12,500.50');
    });

    test('short form drops zero cents', () {
      expect(formatter.formatShort(Money.dollars(15000)), r'$15,000');
    });

    test('short form keeps real cents', () {
      expect(formatter.formatShort(const Money.cents(1999)), r'$19.99');
    });

    test('signed form marks a shortfall with a minus sign', () {
      expect(formatter.formatSigned(Money.dollars(-20)), r'−$20');
    });

    test('signed form leaves zero unsigned', () {
      expect(formatter.formatSigned(Money.zero), r'$0');
    });

    test('editing form has no symbol or grouping', () {
      expect(formatter.formatForEditing(const Money.cents(120050)), '1200.50');
    });
  });
}
