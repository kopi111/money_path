import '../calendar/year_month.dart';
import '../money/money.dart';

/// One expense as the budget sees it.
class SpendingLine {
  const SpendingLine({required this.categoryId, required this.amount});

  final String categoryId;
  final Money amount;
}

/// A month's money in and out. Goal deposits leave the month's budget and
/// withdrawals come back into it, so the budget and the goals always agree.
class MonthLedger {
  MonthLedger({
    required this.month,
    required this.income,
    required List<SpendingLine> spending,
    required this.goalDeposits,
    required this.goalWithdrawals,
    required this.carriedOut,
  }) : spending = List.unmodifiable(spending);

  final YearMonth month;
  final Money income;
  final List<SpendingLine> spending;
  final Money goalDeposits;
  final Money goalWithdrawals;

  /// Leftover already moved on to next month or into a goal at month end.
  final Money carriedOut;

  Money get spent => Money.sum(spending.map((line) => line.amount));

  Money get savedToGoals => goalDeposits - goalWithdrawals;

  Money get remaining => income - spent - savedToGoals - carriedOut;

  /// What is left before any month-end carry-over, for the month-end summary.
  Money get leftover => income - spent - savedToGoals;

  Map<String, Money> get spentByCategory {
    final totals = <String, Money>{};
    for (final line in spending) {
      totals.update(line.categoryId, (sum) => sum + line.amount, ifAbsent: () => line.amount);
    }
    return totals;
  }

  Money spentIn(String categoryId) => spentByCategory[categoryId] ?? Money.zero;
}
