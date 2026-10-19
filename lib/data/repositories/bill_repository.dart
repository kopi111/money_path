import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/id_generator.dart';
import '../../domain/budget/recurring_bill.dart';
import '../../domain/calendar/year_month.dart';
import '../../domain/money/money.dart';
import '../app_database.dart';
import 'row_mapping.dart';
import 'table_watch.dart';

class BillDraft {
  const BillDraft({
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.dueDay,
  });

  final String name;
  final Money amount;
  final String categoryId;
  final int dueDay;
}

class BillRepository {
  BillRepository(this._database, {Clock clock = const Clock(), IdGenerator ids = const IdGenerator()})
      : _clock = clock,
        _ids = ids;

  final AppDatabase _database;
  final Clock _clock;
  final IdGenerator _ids;

  Stream<List<RecurringBill>> watchActive() =>
      watchTables(_database, [_database.recurringBills], loadActive);

  Future<List<RecurringBill>> loadActive() async {
    final rows = await (_database.select(_database.recurringBills)
          ..where((row) => row.deletedAt.isNull() & row.isActive.equals(true))
          ..orderBy([(row) => OrderingTerm.asc(row.dueDay)]))
        .get();
    return rows.map(toBill).toList();
  }

  Future<void> create(BillDraft draft) async {
    final now = _clock.nowUtc();
    await _database.into(_database.recurringBills).insert(RecurringBillsCompanion.insert(
          id: _ids.next(),
          name: draft.name,
          amountCents: draft.amount.cents,
          categoryId: draft.categoryId,
          dueDay: draft.dueDay,
          createdAt: now,
          updatedAt: now,
        ));
  }

  Future<void> update(String billId, BillDraft draft) => _updateBill(
        billId,
        RecurringBillsCompanion(
          name: Value(draft.name),
          amountCents: Value(draft.amount.cents),
          categoryId: Value(draft.categoryId),
          dueDay: Value(draft.dueDay),
        ),
      );

  Future<void> delete(String billId) =>
      _updateBill(billId, RecurringBillsCompanion(deletedAt: Value(_clock.nowUtc())));

  /// Adds this month's expense for every bill not yet posted. Safe to run
  /// any number of times: each bill posts at most once per month.
  Future<int> postDueBills(YearMonth month) => _database.transaction(() async {
        final calendar = BillCalendar(await loadActive());
        final unposted = calendar.unpostedIn(await _billIdsPostedIn(month));
        for (final bill in unposted) {
          await _postBill(bill, month);
        }
        return unposted.length;
      });

  Future<Set<String>> _billIdsPostedIn(YearMonth month) async {
    final rows = await (_database.select(_database.expenses)
          ..where((row) => row.billMonth.equals(month.key)))
        .get();
    return rows.map((row) => row.recurringBillId!).toSet();
  }

  Future<void> _postBill(RecurringBill bill, YearMonth month) async {
    final now = _clock.nowUtc();
    await _database.into(_database.expenses).insert(ExpensesCompanion.insert(
          id: _ids.next(),
          date: bill.dueDateIn(month).toIso(),
          amountCents: bill.amount.cents,
          categoryId: bill.categoryId,
          note: Value(bill.name),
          recurringBillId: Value(bill.id),
          billMonth: Value(month.key),
          createdAt: now,
          updatedAt: now,
        ));
  }

  Future<void> _updateBill(String billId, RecurringBillsCompanion changes) async {
    await (_database.update(_database.recurringBills)..where((row) => row.id.equals(billId)))
        .write(changes.copyWith(updatedAt: Value(_clock.nowUtc())));
  }
}
