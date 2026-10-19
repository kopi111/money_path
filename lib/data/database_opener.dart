import 'dart:io';

import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

import 'app_database.dart';

/// Opens the encrypted database file. The key never touches the disk in the
/// clear; it lives in the platform keystore and is handed in here.
class DatabaseOpener {
  const DatabaseOpener();

  static const fileName = 'money_path.db';

  AppDatabase open(File file, String key) =>
      AppDatabase(NativeDatabase.createInBackground(file, setup: _unlockWith(key)));

  /// Writes an encrypted copy of the open database to [destination].
  Future<void> copyTo(AppDatabase database, File destination) async {
    if (destination.existsSync()) destination.deleteSync();
    await database.customStatement('VACUUM INTO ?', [destination.path]);
  }

  /// True when [file] opens with [key] and reads as a database.
  bool opensWith(File file, String key) {
    final database = sqlite3.open(file.path);
    try {
      _unlockWith(key)(database);
      return true;
    } on SqliteException {
      return false;
    } finally {
      database.close();
    }
  }
}

void Function(Database) _unlockWith(String key) {
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(key)) {
    throw ArgumentError('The database key must be 64 hex characters');
  }
  return (database) {
    database.execute("PRAGMA key = '$key'");
    database.execute('SELECT count(*) FROM sqlite_master');
  };
}
