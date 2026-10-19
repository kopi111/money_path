import '../calendar/calendar_date.dart';
import '../money/money.dart';

enum GoalEntryKind { deposit, withdrawal }

/// Money put into or taken out of a goal.
class GoalEntry {
  const GoalEntry({
    required this.id,
    required this.goalId,
    required this.kind,
    required this.amount,
    required this.date,
    required this.note,
  });

  final String id;
  final String goalId;
  final GoalEntryKind kind;
  final Money amount;
  final CalendarDate date;
  final String note;

  /// Positive for a deposit, negative for a withdrawal.
  Money get signedAmount => kind == GoalEntryKind.deposit ? amount : -amount;
}
