import 'package:drift/drift.dart';

import '../domain/budget/budget_records.dart';
import '../domain/goals/contribution_frequency.dart';
import '../domain/goals/goal.dart';
import '../domain/goals/goal_entry.dart';
import 'seed_categories.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Goals,
  GoalEntries,
  Categories,
  Incomes,
  RecurringBills,
  Expenses,
  MonthClosings,
  Settings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await migrator.createAll();
          await batch((batch) => batch.insertAll(categories, seedCategories(DateTime.now().toUtc())));
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
