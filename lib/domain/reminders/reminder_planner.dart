import '../budget/recurring_bill.dart';
import '../calendar/calendar_date.dart';
import '../goals/goal_progress.dart';
import '../money/money_formatter.dart';

class PlannedReminder {
  const PlannedReminder({required this.day, required this.hour, required this.title, required this.body});

  final CalendarDate day;
  final int hour;
  final String title;
  final String body;
}

/// A goal the planner can remind about.
class RemindableGoal {
  const RemindableGoal({required this.id, required this.name, required this.progress});

  final String id;
  final String name;
  final GoalProgress progress;
}

/// Works out which reminders to schedule; the notification service only
/// delivers them.
class ReminderPlanner {
  const ReminderPlanner({required this.money, required this.billReminderDays, required this.writeDay});

  static const morningHour = 9;
  static const billHorizonDays = 40;

  final MoneyFormatter money;
  final int billReminderDays;
  final String Function(CalendarDate day) writeDay;

  List<PlannedReminder> plan({
    required CalendarDate today,
    required List<RemindableGoal> goals,
    required List<RecurringBill> bills,
  }) =>
      [
        for (final goal in goals) ..._depositReminder(goal, today),
        ..._billReminders(bills, today),
      ];

  Iterable<PlannedReminder> _depositReminder(RemindableGoal goal, CalendarDate today) sync* {
    final progress = goal.progress;
    if (progress.isReached || progress.periodsLeft <= 1) return;
    final schedule = progress.schedule;
    final nextPeriodStart = schedule.periodStart(progress.completedPeriods + 1);
    if (nextPeriodStart.isAfter(schedule.end)) return;
    final frequency = schedule.frequency.periodName;
    yield PlannedReminder(
      day: nextPeriodStart,
      hour: morningHour,
      title: 'Time to make your $frequency\'s deposit',
      body: '${goal.name}: save ${money.formatShort(progress.catchUpPerPeriod)} this $frequency to stay on track.',
    );
  }

  Iterable<PlannedReminder> _billReminders(List<RecurringBill> bills, CalendarDate today) =>
      BillCalendar(bills)
          .upcoming(today: today, days: billHorizonDays)
          .map((upcoming) => (upcoming, upcoming.dueOn.addDays(-billReminderDays)))
          .where((pair) => pair.$2.isAfter(today))
          .map((pair) => PlannedReminder(
                day: pair.$2,
                hour: morningHour,
                title: '${pair.$1.bill.name} is due soon',
                body: '${money.formatShort(pair.$1.bill.amount)} due on ${writeDay(pair.$1.dueOn)}.',
              ));
}
