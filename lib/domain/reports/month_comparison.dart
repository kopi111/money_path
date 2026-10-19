import '../money/money.dart';

/// How one category's spending moved between two months.
sealed class SpendingChange {
  const SpendingChange();

  factory SpendingChange.between({required Money previous, required Money current}) {
    if (previous.isZero && current.isZero) return const NoSpendingEitherMonth();
    if (previous.isZero) return const NewThisMonth();
    return PercentChange(_roundedPercent(current - previous, previous));
  }
}

class PercentChange extends SpendingChange {
  const PercentChange(this.percent);

  /// Positive means more was spent this month.
  final int percent;
}

class NewThisMonth extends SpendingChange {
  const NewThisMonth();
}

class NoSpendingEitherMonth extends SpendingChange {
  const NoSpendingEitherMonth();
}

int _roundedPercent(Money change, Money base) {
  final scaled = change.cents.abs() * 100;
  final rounded = (scaled + base.cents ~/ 2) ~/ base.cents;
  return change.isNegative ? -rounded : rounded;
}
