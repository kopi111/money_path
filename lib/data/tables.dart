// Drift declares CHECK constraints by referring to the column being defined.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

import '../domain/budget/budget_records.dart';
import '../domain/goals/contribution_frequency.dart';
import '../domain/goals/goal.dart';
import '../domain/goals/goal_entry.dart';

/// Every synced record carries a UUID, UTC audit times and a soft-delete
/// marker, so multi-device sync can be added later without reshaping tables.
mixin SyncedRecord on Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// Calendar days are ISO text ("2026-10-01") so they sort as strings and never
// shift with time zones; months are "2026-10".

@DataClassName('GoalRow')
class Goals extends Table with SyncedRecord {
  TextColumn get name => text().withLength(min: 1, max: 60)();
  IntColumn get targetCents => integer().check(targetCents.isBiggerThanValue(0))();
  TextColumn get startDate => text().withLength(min: 10, max: 10)();
  TextColumn get endDate => text().withLength(min: 10, max: 10)();
  TextColumn get frequency => textEnum<ContributionFrequency>()();
  TextColumn get state => textEnum<GoalState>()();
  TextColumn get kind => textEnum<GoalKind>()();

  @override
  List<String> get customConstraints => ['CHECK (start_date < end_date)'];
}

@TableIndex(name: 'goal_entries_goal_date', columns: {#goalId, #date})
@DataClassName('GoalEntryRow')
class GoalEntries extends Table with SyncedRecord {
  TextColumn get goalId => text().references(Goals, #id, onDelete: KeyAction.restrict)();
  TextColumn get kind => textEnum<GoalEntryKind>()();
  IntColumn get amountCents => integer().check(amountCents.isBiggerThanValue(0))();
  TextColumn get date => text().withLength(min: 10, max: 10)();
  TextColumn get note => text().withLength(max: 200).withDefault(const Constant(''))();
}

@DataClassName('CategoryRow')
class Categories extends Table with SyncedRecord {
  TextColumn get name => text().withLength(min: 1, max: 40).unique()();
  TextColumn get iconName => text().withLength(min: 1, max: 40)();
  IntColumn get sortOrder => integer()();
  IntColumn get monthlyLimitCents =>
      integer().nullable().check(monthlyLimitCents.isBiggerThanValue(0))();
}

@TableIndex(name: 'incomes_month', columns: {#month})
@DataClassName('IncomeRow')
class Incomes extends Table with SyncedRecord {
  TextColumn get month => text().withLength(min: 7, max: 7)();
  TextColumn get source => text().withLength(min: 1, max: 60)();
  IntColumn get amountCents => integer().check(amountCents.isBiggerThanValue(0))();
  TextColumn get receivedOn => text().withLength(min: 10, max: 10)();
  TextColumn get kind => textEnum<IncomeKind>()();
}

@DataClassName('RecurringBillRow')
class RecurringBills extends Table with SyncedRecord {
  TextColumn get name => text().withLength(min: 1, max: 60)();
  IntColumn get amountCents => integer().check(amountCents.isBiggerThanValue(0))();
  TextColumn get categoryId => text().references(Categories, #id, onDelete: KeyAction.restrict)();
  IntColumn get dueDay => integer().check(dueDay.isBetweenValues(1, 31))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

@TableIndex(name: 'expenses_date', columns: {#date})
@TableIndex(name: 'expenses_category_date', columns: {#categoryId, #date})
@DataClassName('ExpenseRow')
class Expenses extends Table with SyncedRecord {
  TextColumn get date => text().withLength(min: 10, max: 10)();
  IntColumn get amountCents => integer().check(amountCents.isBiggerThanValue(0))();
  TextColumn get categoryId => text().references(Categories, #id, onDelete: KeyAction.restrict)();
  TextColumn get note => text().withLength(max: 200).withDefault(const Constant(''))();
  TextColumn get receiptPath => text().nullable()();

  /// Set only on expenses posted automatically from a recurring bill.
  TextColumn get recurringBillId =>
      text().nullable().references(RecurringBills, #id, onDelete: KeyAction.restrict)();
  TextColumn get billMonth => text().nullable().withLength(min: 7, max: 7)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {recurringBillId, billMonth},
      ];

  @override
  List<String> get customConstraints =>
      ['CHECK ((recurring_bill_id IS NULL) = (bill_month IS NULL))'];
}

/// A month's leftover, moved on at month end. One closing per month.
@DataClassName('MonthClosingRow')
class MonthClosings extends Table {
  TextColumn get month => text().withLength(min: 7, max: 7)();
  IntColumn get leftoverCents => integer().check(leftoverCents.isBiggerThanValue(0))();
  TextColumn get destination => textEnum<LeftoverDestination>()();
  TextColumn get goalId => text().nullable().references(Goals, #id, onDelete: KeyAction.restrict)();
  DateTimeColumn get closedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {month};

  @override
  List<String> get customConstraints =>
      ["CHECK ((destination = 'goal') = (goal_id IS NOT NULL))"];
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text().withLength(min: 1, max: 60)();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
