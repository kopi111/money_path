/// An exact amount of money held as whole cents. No floating point is ever
/// involved, so a total always equals the sum of its parts.
class Money implements Comparable<Money> {
  const Money.cents(this.cents);

  factory Money.dollars(int dollars) => Money.cents(dollars * centsPerDollar);

  static const zero = Money.cents(0);
  static const centsPerDollar = 100;

  final int cents;

  bool get isZero => cents == 0;
  bool get isPositive => cents > 0;
  bool get isNegative => cents < 0;

  Money operator +(Money other) => Money.cents(cents + other.cents);
  Money operator -(Money other) => Money.cents(cents - other.cents);
  Money operator -() => Money.cents(-cents);

  Money times(int factor) => Money.cents(cents * factor);

  Money abs() => Money.cents(cents.abs());

  /// Splits this amount into [parts] equal instalments, rounding each one up
  /// to the next cent so that paying every instalment always reaches the whole.
  Money instalmentOf(int parts) {
    if (parts <= 0) {
      throw ArgumentError.value(parts, 'parts', 'must be at least 1');
    }
    return Money.cents(_ceilDivide(cents, parts));
  }

  /// Whole percent of [whole] that this amount represents, rounded down.
  int percentOf(Money whole) {
    if (!whole.isPositive) {
      throw ArgumentError.value(whole, 'whole', 'must be positive');
    }
    return (cents * 100) ~/ whole.cents;
  }

  bool operator <(Money other) => cents < other.cents;
  bool operator <=(Money other) => cents <= other.cents;
  bool operator >(Money other) => cents > other.cents;
  bool operator >=(Money other) => cents >= other.cents;

  static Money smallerOf(Money a, Money b) => a <= b ? a : b;
  static Money largerOf(Money a, Money b) => a >= b ? a : b;

  static Money sum(Iterable<Money> amounts) =>
      amounts.fold(Money.zero, (total, amount) => total + amount);

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) => other is Money && other.cents == cents;

  @override
  int get hashCode => cents.hashCode;

  @override
  String toString() => 'Money($cents¢)';
}

int _ceilDivide(int numerator, int denominator) {
  final quotient = numerator ~/ denominator;
  final hasRemainder = numerator % denominator != 0;
  return hasRemainder && numerator > 0 ? quotient + 1 : quotient;
}
