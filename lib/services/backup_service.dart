import 'dart:io';

import 'package:path/path.dart' as p;

import '../data/app_database.dart';
import '../data/database_opener.dart';

class BackupFile {
  const BackupFile(this.file, this.takenAt);

  final File file;
  final DateTime takenAt;
}

/// Keeps a rolling set of encrypted copies of the database on the phone.
class BackupService {
  BackupService({required this.folder, this.keep = 7, DatabaseOpener opener = const DatabaseOpener()})
      : _opener = opener;

  final Directory folder;
  final int keep;
  final DatabaseOpener _opener;

  static const _prefix = 'money_path-';
  static const _suffix = '.db';
  static const automaticEvery = Duration(hours: 24);

  List<BackupFile> list() {
    if (!folder.existsSync()) return const [];
    final backups = folder
        .listSync()
        .whereType<File>()
        .where((file) => p.basename(file.path).startsWith(_prefix) && file.path.endsWith(_suffix))
        .map((file) => BackupFile(file, file.lastModifiedSync()))
        .toList();
    return backups..sort((a, b) => b.takenAt.compareTo(a.takenAt));
  }

  Future<BackupFile> backUpNow(AppDatabase database) async {
    folder.createSync(recursive: true);
    final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final destination = File(p.join(folder.path, '$_prefix$stamp$_suffix'));
    await _opener.copyTo(database, destination);
    _pruneOldBackups();
    return BackupFile(destination, destination.lastModifiedSync());
  }

  /// Backs up when the newest backup is older than a day. Returns whether it ran.
  Future<bool> backUpIfDue(AppDatabase database) async {
    final newest = list();
    if (newest.isNotEmpty && DateTime.now().difference(newest.first.takenAt) < automaticEvery) return false;
    await backUpNow(database);
    return true;
  }

  void _pruneOldBackups() {
    for (final old in list().skip(keep)) {
      old.file.deleteSync();
    }
  }
}
