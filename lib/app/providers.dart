import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
import '../data/app_database.dart';
import '../data/repositories/bill_repository.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/goal_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../domain/budget/budget_records.dart';
import '../domain/budget/recurring_bill.dart';
import '../domain/calendar/calendar_date.dart';
import '../domain/calendar/year_month.dart';
import '../domain/goals/goal.dart';
import '../domain/goals/goal_progress.dart';
import '../domain/goals/goal_standing.dart';
import '../domain/money/money_formatter.dart';

/// Replaced at start-up with the unlocked, encrypted database.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw StateError('The database is opened before the app starts'),
);

final clockProvider = Provider<Clock>((ref) => const Clock());

final goalRepositoryProvider = Provider(
  (ref) => GoalRepository(ref.watch(databaseProvider), clock: ref.watch(clockProvider)),
);

final budgetRepositoryProvider = Provider(
  (ref) => BudgetRepository(ref.watch(databaseProvider), clock: ref.watch(clockProvider)),
);

final categoryRepositoryProvider = Provider(
  (ref) => CategoryRepository(ref.watch(databaseProvider), clock: ref.watch(clockProvider)),
);

final billRepositoryProvider = Provider(
  (ref) => BillRepository(ref.watch(databaseProvider), clock: ref.watch(clockProvider)),
);

final settingsRepositoryProvider = Provider((ref) => SettingsRepository(ref.watch(databaseProvider)));

final settingsProvider = StreamProvider<AppSettings>((ref) => ref.watch(settingsRepositoryProvider).watch());

/// Settings, falling back to the defaults while the first read is in flight.
final currentSettingsProvider = Provider<AppSettings>(
  (ref) => ref.watch(settingsProvider).valueOrNull ?? AppSettings.defaults,
);

final moneyFormatterProvider = Provider<MoneyFormatter>(
  (ref) => MoneyFormatter(ref.watch(currentSettingsProvider).currency),
);

final todayProvider = Provider<CalendarDate>((ref) => ref.watch(clockProvider).today());

final goalsProvider = StreamProvider<List<GoalWithEntries>>((ref) => ref.watch(goalRepositoryProvider).watchAll());

final categoriesProvider = StreamProvider<List<Category>>((ref) => ref.watch(categoryRepositoryProvider).watchAll());

final billsProvider = StreamProvider<List<RecurringBill>>((ref) => ref.watch(billRepositoryProvider).watchActive());

final monthProvider = StreamProvider.family<MonthSnapshot, YearMonth>(
  (ref, month) => ref.watch(budgetRepositoryProvider).watchMonth(month),
);

/// A goal with its reading for today.
class GoalView {
  const GoalView(this.record, this.progress);

  final GoalWithEntries record;
  final GoalProgress progress;

  GoalStanding get standing =>
      record.goal.state == GoalState.paused ? const PausedGoal() : progress.standing;
}

final goalViewsProvider = Provider<AsyncValue<List<GoalView>>>((ref) {
  final today = ref.watch(todayProvider);
  final threshold = ref.watch(currentSettingsProvider).amberThresholdPercent;
  return ref.watch(goalsProvider).whenData((goals) => [
        for (final record in goals)
          GoalView(
            record,
            GoalProgress(
              schedule: record.goal.schedule,
              saved: record.saved,
              today: today,
              amberThresholdPercent: threshold,
            ),
          ),
      ]);
});

extension CategoryLookup on List<Category> {
  Category byId(String id) => firstWhere(
        (category) => category.id == id,
        orElse: () => Category(id: id, name: 'Unknown', iconName: 'other', monthlyLimit: const NoLimit()),
      );
}
