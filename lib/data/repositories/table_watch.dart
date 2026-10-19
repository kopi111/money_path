import 'package:drift/drift.dart';

/// Loads once, then reloads whenever any of [tables] changes.
Stream<T> watchTables<T>(
  DatabaseConnectionUser database,
  Iterable<TableInfo> tables,
  Future<T> Function() load,
) async* {
  yield await load();
  await for (final _ in database.tableUpdates(TableUpdateQuery.onAllTables(tables))) {
    yield await load();
  }
}
