import '../money/money.dart';

sealed class EmergencyFundSuggestion {
  const EmergencyFundSuggestion();
}

class SuggestedTarget extends EmergencyFundSuggestion {
  const SuggestedTarget({
    required this.target,
    required this.averageMonthlySpending,
    required this.monthsAveraged,
  });

  final Money target;
  final Money averageMonthlySpending;
  final int monthsAveraged;
}

/// No finished month with spending yet, so the target must be typed in.
class NoSpendingHistory extends EmergencyFundSuggestion {
  const NoSpendingHistory();
}

/// The preset "emergency fund" goal: a few months of average spending.
class EmergencyFundTemplate {
  const EmergencyFundTemplate({this.monthsCovered = 3, this.monthsToAverage = 3});

  final int monthsCovered;
  final int monthsToAverage;

  /// [monthlySpending] runs from the most recent finished month backwards.
  EmergencyFundSuggestion suggest(List<Money> monthlySpending) {
    final recent = monthlySpending.where((total) => total.isPositive).take(monthsToAverage).toList();
    if (recent.isEmpty) return const NoSpendingHistory();
    final average = Money.sum(recent).instalmentOf(recent.length);
    return SuggestedTarget(
      target: average.times(monthsCovered),
      averageMonthlySpending: average,
      monthsAveraged: recent.length,
    );
  }
}
