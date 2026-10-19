import '../data/app_database.dart';
import '../data/repositories/bill_repository.dart';
import '../data/repositories/goal_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../domain/calendar/calendar_date.dart';
import '../domain/calendar/year_month.dart';
import '../domain/goals/goal.dart';
import '../domain/goals/goal_progress.dart';
import '../domain/goals/goal_standing.dart';
import '../domain/money/money_formatter.dart';
import '../domain/reminders/reminder_planner.dart';
import '../ui/format/dates.dart';
import 'backup_service.dart';
import 'notification_service.dart';

/// The jobs run each time the app opens: post this month's bills, take the
/// daily backup, rebuild reminders and warn about goals that fell behind.
class DailyUpkeep {
  const DailyUpkeep({
    required this.database,
    required this.goals,
    required this.bills,
    required this.settings,
    required this.backups,
    required this.notifications,
  });

  final AppDatabase database;
  final GoalRepository goals;
  final BillRepository bills;
  final SettingsRepository settings;
  final BackupService backups;
  final NotificationService notifications;

  Future<void> run(CalendarDate today) async {
    await bills.postDueBills(YearMonth.of(today));
    await backups.backUpIfDue(database);
    await refreshReminders(today);
  }

  Future<void> refreshReminders(CalendarDate today) async {
    final preferences = await settings.load();
    if (!preferences.remindersOn) {
      await notifications.cancelAll();
      return;
    }
    final money = MoneyFormatter(preferences.currency);
    final openGoals = await _activeGoals(today, preferences.amberThresholdPercent);
    final planner = ReminderPlanner(
      money: money,
      billReminderDays: preferences.billReminderDays,
      writeDay: Dates.dayMonth,
    );
    await notifications.replaceScheduled(planner.plan(
      today: today,
      goals: openGoals,
      bills: await bills.loadActive(),
    ));
    await _warnAboutGoalsBehind(openGoals, money);
  }

  Future<List<RemindableGoal>> _activeGoals(CalendarDate today, int amberThreshold) async => [
        for (final record in await goals.loadAll())
          if (record.goal.state == GoalState.active)
            RemindableGoal(
              id: record.goal.id,
              name: record.goal.name,
              progress: GoalProgress(
                schedule: record.goal.schedule,
                saved: record.saved,
                today: today,
                amberThresholdPercent: amberThreshold,
              ),
            ),
      ];

  Future<void> _warnAboutGoalsBehind(List<RemindableGoal> openGoals, MoneyFormatter money) async {
    for (final (slot, goal) in openGoals.indexed) {
      final standing = goal.progress.standing;
      if (standing is! BehindPlan || standing.isSlight) continue;
      final marker = 'behind:${goal.id}:${goal.progress.completedPeriods}';
      if (!await settings.claimOnce(marker)) continue;
      await notifications.warnGoalBehind(
        slot: slot,
        title: '${goal.name} has fallen behind',
        body: '${money.formatShort(standing.behind)} behind. '
            'Save ${money.formatShort(goal.progress.catchUpPerPeriod)} a ${goal.progress.schedule.frequency.periodName} to catch up.',
      );
    }
  }
}
