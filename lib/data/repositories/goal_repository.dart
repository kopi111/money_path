import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/id_generator.dart';
import '../../domain/calendar/calendar_date.dart';
import '../../domain/goals/contribution_frequency.dart';
import '../../domain/goals/goal.dart';
import '../../domain/goals/goal_entry.dart';
import '../../domain/goals/savings_schedule.dart';
import '../../domain/money/money.dart';
import '../app_database.dart';
import 'table_watch.dart';

/// A goal together with everything saved into it so far.
class GoalWithEntries {
  const GoalWithEntries(this.goal, this.entries);

  final Goal goal;
  final List<GoalEntry> entries;

  Money get saved => Money.sum(entries.map((entry) => entry.signedAmount));
}

class GoalDraft {
  const GoalDraft({
    required this.name,
    required this.target,
    required this.start,
    required this.end,
    required this.frequency,
    this.kind = GoalKind.regular,
  });

  final String name;
  final Money target;
  final CalendarDate start;
  final CalendarDate end;
  final ContributionFrequency frequency;
  final GoalKind kind;
}

class GoalRepository {
  GoalRepository(this._database, {Clock clock = const Clock(), IdGenerator ids = const IdGenerator()})
      : _clock = clock,
        _ids = ids;

  final AppDatabase _database;
  final Clock _clock;
  final IdGenerator _ids;

  Stream<List<GoalWithEntries>> watchAll() =>
      watchTables(_database, [_database.goals, _database.goalEntries], _loadAll);

  Future<List<GoalWithEntries>> loadAll() => _loadAll();

  Future<String> create(GoalDraft draft) async {
    final id = _ids.next();
    final now = _clock.nowUtc();
    await _database.into(_database.goals).insert(GoalsCompanion.insert(
          id: id,
          name: draft.name,
          targetCents: draft.target.cents,
          startDate: draft.start.toIso(),
          endDate: draft.end.toIso(),
          frequency: draft.frequency,
          state: GoalState.active,
          kind: draft.kind,
          createdAt: now,
          updatedAt: now,
        ));
    return id;
  }

  Future<void> update(String goalId, GoalDraft draft) => _updateGoal(
        goalId,
        GoalsCompanion(
          name: Value(draft.name),
          targetCents: Value(draft.target.cents),
          startDate: Value(draft.start.toIso()),
          endDate: Value(draft.end.toIso()),
          frequency: Value(draft.frequency),
        ),
      );

  Future<void> changeState(String goalId, GoalState state) =>
      _updateGoal(goalId, GoalsCompanion(state: Value(state)));

  Future<void> delete(String goalId) =>
      _updateGoal(goalId, GoalsCompanion(deletedAt: Value(_clock.nowUtc())));

  Future<void> addEntry({
    required String goalId,
    required GoalEntryKind kind,
    required Money amount,
    required CalendarDate date,
    String note = '',
  }) async {
    final now = _clock.nowUtc();
    await _database.into(_database.goalEntries).insert(GoalEntriesCompanion.insert(
          id: _ids.next(),
          goalId: goalId,
          kind: kind,
          amountCents: amount.cents,
          date: date.toIso(),
          note: Value(note),
          createdAt: now,
          updatedAt: now,
        ));
  }

  Future<void> deleteEntry(String entryId) async {
    final now = _clock.nowUtc();
    await (_database.update(_database.goalEntries)..where((row) => row.id.equals(entryId)))
        .write(GoalEntriesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }

  Future<void> _updateGoal(String goalId, GoalsCompanion changes) async {
    await (_database.update(_database.goals)..where((row) => row.id.equals(goalId)))
        .write(changes.copyWith(updatedAt: Value(_clock.nowUtc())));
  }

  Future<List<GoalWithEntries>> _loadAll() async {
    final goalRows = await (_database.select(_database.goals)
          ..where((row) => row.deletedAt.isNull())
          ..orderBy([(row) => OrderingTerm.asc(row.endDate)]))
        .get();
    final entryRows = await (_database.select(_database.goalEntries)
          ..where((row) => row.deletedAt.isNull())
          ..orderBy([(row) => OrderingTerm.desc(row.date), (row) => OrderingTerm.desc(row.createdAt)]))
        .get();
    return [
      for (final row in goalRows)
        GoalWithEntries(
          _toGoal(row),
          entryRows.where((entry) => entry.goalId == row.id).map(_toEntry).toList(),
        ),
    ];
  }
}

Goal _toGoal(GoalRow row) => Goal(
      id: row.id,
      name: row.name,
      schedule: SavingsSchedule(
        target: Money.cents(row.targetCents),
        start: CalendarDate.parse(row.startDate),
        end: CalendarDate.parse(row.endDate),
        frequency: row.frequency,
      ),
      state: row.state,
      kind: row.kind,
    );

GoalEntry _toEntry(GoalEntryRow row) => GoalEntry(
      id: row.id,
      goalId: row.goalId,
      kind: row.kind,
      amount: Money.cents(row.amountCents),
      date: CalendarDate.parse(row.date),
      note: row.note,
    );
