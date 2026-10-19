import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/id_generator.dart';
import '../../domain/budget/budget_records.dart';
import '../../domain/money/money.dart';
import '../app_database.dart';
import 'row_mapping.dart';
import 'table_watch.dart';

class CategoryRepository {
  CategoryRepository(this._database, {Clock clock = const Clock(), IdGenerator ids = const IdGenerator()})
      : _clock = clock,
        _ids = ids;

  final AppDatabase _database;
  final Clock _clock;
  final IdGenerator _ids;

  Stream<List<Category>> watchAll() => watchTables(_database, [_database.categories], loadAll);

  Future<List<Category>> loadAll() async {
    final rows = await (_database.select(_database.categories)
          ..where((row) => row.deletedAt.isNull())
          ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
        .get();
    return rows.map(toCategory).toList();
  }

  Future<void> add({required String name, required String iconName}) async {
    final now = _clock.nowUtc();
    final nextOrder = await _nextSortOrder();
    await _database.into(_database.categories).insert(CategoriesCompanion.insert(
          id: _ids.next(),
          name: name,
          iconName: iconName,
          sortOrder: nextOrder,
          createdAt: now,
          updatedAt: now,
        ));
  }

  Future<void> setLimit(String categoryId, Money limit) =>
      _writeLimit(categoryId, Value(limit.cents));

  Future<void> clearLimit(String categoryId) => _writeLimit(categoryId, const Value(null));

  Future<void> _writeLimit(String categoryId, Value<int?> limitCents) async {
    await (_database.update(_database.categories)..where((row) => row.id.equals(categoryId))).write(
      CategoriesCompanion(monthlyLimitCents: limitCents, updatedAt: Value(_clock.nowUtc())),
    );
  }

  Future<int> _nextSortOrder() async {
    final highest = _database.categories.sortOrder.max();
    final query = _database.selectOnly(_database.categories)..addColumns([highest]);
    final row = await query.getSingle();
    return (row.read(highest) ?? -1) + 1;
  }
}
