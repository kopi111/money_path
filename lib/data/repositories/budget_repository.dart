import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/id_generator.dart';
import '../../domain/budget/budget_records.dart';
import '../../domain/budget/month_ledger.dart';
import '../../domain/calendar/calendar_date.dart';
import '../../domain/calendar/year_month.dart';
import '../../domain/goals/goal_entry.dart';
import '../../domain/money/money.dart';
import '../app_database.dart';
import 'row_mapping.dart';
import 'table_watch.dart';

/// Everything recorded in one month, with its ledger worked out.
class MonthSnapshot {
  const MonthSnapshot({
    required this.ledger,
    required this.incomes,
    required this.expenses,
    required this.monthEnd,
  });

  final MonthLedger ledger;
  final List<Income> incomes;
  final List<Expense> expenses;
  final MonthEnd monthEnd;
}

class ExpenseDraft {
  const ExpenseDraft({
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note = '',
    this.receipt = const NoReceipt(),
  });

  final Money amount;
  final String categoryId;
  final CalendarDate date;
  final String note;
  final Receipt receipt;
}

/// What to look for when searching spending. Empty parts match everything.
class ExpenseFilter {
  const ExpenseFilter({
    required this.from,
    required this.to,
    this.categoryIds = const {},
    this.minimum = Money.zero,
    this.maximum = Money.zero,
    this.words = '',
  });

  final CalendarDate from;
  final CalendarDate to;
  final Set<String> categoryIds;
  final Money minimum;

  /// Zero means no upper bound.
  final Money maximum;
  final String words;
}

class BudgetRepository {
  BudgetRepository(this._database, {Clock clock = const Clock(), IdGenerator ids = const IdGenerator()})
      : _clock = clock,
        _ids = ids;

  final AppDatabase _database;
  final Clock _clock;
  final IdGenerator _ids;

  Stream<MonthSnapshot> watchMonth(YearMonth month) => watchTables(
        _database,
        [_database.incomes, _database.expenses, _database.goalEntries, _database.monthClosings, _database.goals],
        () => loadMonth(month),
      );

  Future<MonthSnapshot> loadMonth(YearMonth month) async {
    final incomes = await _incomesIn(month);
    final expenses = await expensesBetween(month.firstDay, month.lastDay);
    final goalEntries = await _goalEntriesIn(month);
    final monthEnd = await _monthEndOf(month);
    return MonthSnapshot(
      ledger: MonthLedger(
        month: month,
        income: Money.sum(incomes.map((income) => income.amount)),
        spending: [
          for (final expense in expenses) SpendingLine(categoryId: expense.categoryId, amount: expense.amount),
        ],
        goalDeposits: _totalOf(goalEntries, GoalEntryKind.deposit),
        goalWithdrawals: _totalOf(goalEntries, GoalEntryKind.withdrawal),
        carriedOut: _carriedOut(monthEnd),
      ),
      incomes: incomes,
      expenses: expenses,
      monthEnd: monthEnd,
    );
  }

  Future<List<Expense>> expensesBetween(CalendarDate first, CalendarDate last) async {
    final rows = await (_database.select(_database.expenses)
          ..where((row) =>
              row.deletedAt.isNull() & row.date.isBetweenValues(first.toIso(), last.toIso()))
          ..orderBy([(row) => OrderingTerm.desc(row.date), (row) => OrderingTerm.desc(row.createdAt)]))
        .get();
    return rows.map(toExpense).toList();
  }

  Future<List<Income>> allIncomes() async {
    final rows = await (_database.select(_database.incomes)
          ..where((row) => row.deletedAt.isNull())
          ..orderBy([(row) => OrderingTerm.asc(row.receivedOn)]))
        .get();
    return rows.map(toIncome).toList();
  }

  Future<List<Expense>> search(ExpenseFilter filter) async {
    final query = _database.select(_database.expenses)
      ..where((row) =>
          row.deletedAt.isNull() &
          row.date.isBetweenValues(filter.from.toIso(), filter.to.toIso()) &
          row.amountCents.isBiggerOrEqualValue(filter.minimum.cents))
      ..orderBy([(row) => OrderingTerm.desc(row.date), (row) => OrderingTerm.desc(row.createdAt)]);
    if (filter.maximum.isPositive) {
      query.where((row) => row.amountCents.isSmallerOrEqualValue(filter.maximum.cents));
    }
    if (filter.categoryIds.isNotEmpty) {
      query.where((row) => row.categoryId.isIn(filter.categoryIds));
    }
    if (filter.words.trim().isNotEmpty) {
      query.where((row) => row.note.like('%${_escapeLike(filter.words.trim())}%', escapeChar: r'\'));
    }
    return (await query.get()).map(toExpense).toList();
  }

  /// Total spending for each of the [count] months before [month], newest first.
  Future<List<Money>> spendingInMonthsBefore(YearMonth month, int count) async {
    final totals = <Money>[];
    var cursor = month.previous;
    for (var index = 0; index < count; index++) {
      final expenses = await expensesBetween(cursor.firstDay, cursor.lastDay);
      totals.add(Money.sum(expenses.map((expense) => expense.amount)));
      cursor = cursor.previous;
    }
    return totals;
  }

  Future<void> addIncome({required YearMonth month, required String source, required Money amount}) async {
    final now = _clock.nowUtc();
    final today = _clock.today();
    await _database.into(_database.incomes).insert(IncomesCompanion.insert(
          id: _ids.next(),
          month: month.key,
          source: source,
          amountCents: amount.cents,
          receivedOn: (month.contains(today) ? today : month.firstDay).toIso(),
          kind: IncomeKind.earned,
          createdAt: now,
          updatedAt: now,
        ));
  }

  Future<void> deleteIncome(String incomeId) async {
    final now = _clock.nowUtc();
    await (_database.update(_database.incomes)..where((row) => row.id.equals(incomeId)))
        .write(IncomesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }

  Future<String> addExpense(ExpenseDraft draft) async {
    final id = _ids.next();
    final now = _clock.nowUtc();
    await _database.into(_database.expenses).insert(ExpensesCompanion.insert(
          id: id,
          date: draft.date.toIso(),
          amountCents: draft.amount.cents,
          categoryId: draft.categoryId,
          note: Value(draft.note),
          receiptPath: Value(_receiptPathOf(draft.receipt)),
          createdAt: now,
          updatedAt: now,
        ));
    return id;
  }

  Future<void> updateExpense(String expenseId, ExpenseDraft draft) async {
    await (_database.update(_database.expenses)..where((row) => row.id.equals(expenseId))).write(
      ExpensesCompanion(
        date: Value(draft.date.toIso()),
        amountCents: Value(draft.amount.cents),
        categoryId: Value(draft.categoryId),
        note: Value(draft.note),
        receiptPath: Value(_receiptPathOf(draft.receipt)),
        updatedAt: Value(_clock.nowUtc()),
      ),
    );
  }

  Future<void> deleteExpense(String expenseId) async {
    final now = _clock.nowUtc();
    await (_database.update(_database.expenses)..where((row) => row.id.equals(expenseId)))
        .write(ExpensesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }

  /// Moves the month's leftover into next month's income.
  Future<void> carryLeftoverToNextMonth(YearMonth month, {required String monthName}) =>
      _database.transaction(() async {
        final leftover = await _leftoverToMove(month);
        await _recordClosing(month, leftover, LeftoverDestination.nextMonth, const Value(null));
        final now = _clock.nowUtc();
        await _database.into(_database.incomes).insert(IncomesCompanion.insert(
              id: _ids.next(),
              month: month.next.key,
              source: 'Left over from $monthName',
              amountCents: leftover.cents,
              receivedOn: month.next.firstDay.toIso(),
              kind: IncomeKind.carriedForward,
              createdAt: now,
              updatedAt: now,
            ));
      });

  /// Moves the month's leftover into a goal as a deposit on the month's last day.
  Future<void> moveLeftoverToGoal(YearMonth month, {required String goalId, required String monthName}) =>
      _database.transaction(() async {
        final leftover = await _leftoverToMove(month);
        await _recordClosing(month, leftover, LeftoverDestination.goal, Value(goalId));
        final now = _clock.nowUtc();
        await _database.into(_database.goalEntries).insert(GoalEntriesCompanion.insert(
              id: _ids.next(),
              goalId: goalId,
              kind: GoalEntryKind.deposit,
              amountCents: leftover.cents,
              date: month.lastDay.toIso(),
              note: Value('Left over from $monthName'),
              createdAt: now,
              updatedAt: now,
            ));
      });

  Future<Money> _leftoverToMove(YearMonth month) async {
    final snapshot = await loadMonth(month);
    if (snapshot.monthEnd is LeftoverMoved) {
      throw StateError('The leftover for ${month.key} has already been moved');
    }
    if (!snapshot.ledger.leftover.isPositive) {
      throw StateError('Nothing is left over in ${month.key}');
    }
    return snapshot.ledger.leftover;
  }

  Future<void> _recordClosing(
    YearMonth month,
    Money leftover,
    LeftoverDestination destination,
    Value<String?> goalId,
  ) async {
    await _database.into(_database.monthClosings).insert(MonthClosingsCompanion.insert(
          month: month.key,
          leftoverCents: leftover.cents,
          destination: destination,
          goalId: goalId,
          closedAt: _clock.nowUtc(),
        ));
  }

  Future<List<Income>> _incomesIn(YearMonth month) async {
    final rows = await (_database.select(_database.incomes)
          ..where((row) => row.deletedAt.isNull() & row.month.equals(month.key))
          ..orderBy([(row) => OrderingTerm.asc(row.receivedOn)]))
        .get();
    return rows.map(toIncome).toList();
  }

  Future<List<GoalEntryRow>> _goalEntriesIn(YearMonth month) {
    return (_database.select(_database.goalEntries).join([
      innerJoin(_database.goals, _database.goals.id.equalsExp(_database.goalEntries.goalId)),
    ])
          ..where(_database.goalEntries.deletedAt.isNull() &
              _database.goals.deletedAt.isNull() &
              _database.goalEntries.date.isBetweenValues(month.firstDay.toIso(), month.lastDay.toIso())))
        .map((row) => row.readTable(_database.goalEntries))
        .get();
  }

  Future<MonthEnd> _monthEndOf(YearMonth month) async {
    final query = _database.select(_database.monthClosings).join([
      leftOuterJoin(_database.goals, _database.goals.id.equalsExp(_database.monthClosings.goalId)),
    ])
      ..where(_database.monthClosings.month.equals(month.key));
    final row = await query.getSingleOrNull();
    if (row == null) return const MonthStillOpen();
    final closing = row.readTable(_database.monthClosings);
    return LeftoverMoved(MonthClosing(
      month: month,
      leftover: Money.cents(closing.leftoverCents),
      destination: closing.destination,
      goalName: row.readTableOrNull(_database.goals)?.name ?? '',
    ));
  }
}

String _escapeLike(String words) =>
    words.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

Money _totalOf(List<GoalEntryRow> entries, GoalEntryKind kind) => Money.sum(
      entries.where((entry) => entry.kind == kind).map((entry) => Money.cents(entry.amountCents)),
    );

Money _carriedOut(MonthEnd monthEnd) => switch (monthEnd) {
      LeftoverMoved(:final closing) when closing.destination == LeftoverDestination.nextMonth =>
        closing.leftover,
      _ => Money.zero,
    };

String? _receiptPathOf(Receipt receipt) => switch (receipt) {
      ReceiptPhoto(:final path) => path,
      NoReceipt() => null,
    };
