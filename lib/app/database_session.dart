import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/app_database.dart';
import '../data/database_opener.dart';
import '../security/secret_store.dart';
import '../services/backup_service.dart';

/// The open, encrypted database plus the folders that belong with it.
class DatabaseSession {
  DatabaseSession._(this.database, this._file, this._key, this.backups, this.receiptsFolder);

  static Future<DatabaseSession> open(SecretStore secrets) async {
    final documents = await getApplicationDocumentsDirectory();
    final file = File(p.join(documents.path, DatabaseOpener.fileName));
    final key = await secrets.databaseKey();
    final backups = BackupService(folder: Directory(p.join(documents.path, 'backups')));
    final receipts = Directory(p.join(documents.path, 'receipts'))..createSync(recursive: true);
    return DatabaseSession._(const DatabaseOpener().open(file, key), file, key, backups, receipts);
  }

  final AppDatabase database;
  final File _file;
  final String _key;
  final BackupService backups;
  final Directory receiptsFolder;

  /// Replaces the live database with [backup] and opens it again.
  Future<DatabaseSession> restore(BackupFile backup) async {
    if (!const DatabaseOpener().opensWith(backup.file, _key)) {
      throw StateError('That backup cannot be opened on this phone');
    }
    final incoming = backup.file.copySync('${_file.path}.restoring');
    await backups.backUpNow(database);
    await database.close();
    incoming.renameSync(_file.path);
    return DatabaseSession._(const DatabaseOpener().open(_file, _key), _file, _key, backups, receiptsFolder);
  }
}
