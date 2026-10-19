import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_path/data/database_opener.dart';
import 'package:money_path/data/repositories/settings_repository.dart';

final key = 'a' * 64;
final otherKey = 'b' * 64;

void main() {
  late Directory folder;

  setUp(() => folder = Directory.systemTemp.createTempSync('money_path_test'));
  tearDown(() => folder.deleteSync(recursive: true));

  Future<File> writeEncryptedDatabase() async {
    final file = File('${folder.path}/money.db');
    final database = const DatabaseOpener().open(file, key);
    await SettingsRepository(database).save(SettingKey.currency, 'JMD');
    await database.close();
    return file;
  }

  test('the database file does not contain readable text', () async {
    final file = await writeEncryptedDatabase();
    final bytes = String.fromCharCodes(file.readAsBytesSync());
    expect(bytes.contains('SQLite format 3'), isFalse);
    expect(bytes.contains('currency'), isFalse);
  });

  test('the database opens with its key', () async {
    final file = await writeEncryptedDatabase();
    expect(const DatabaseOpener().opensWith(file, key), isTrue);
  });

  test('the database refuses any other key', () async {
    final file = await writeEncryptedDatabase();
    expect(const DatabaseOpener().opensWith(file, otherKey), isFalse);
  });

  test('a backup copy is encrypted with the same key', () async {
    final file = File('${folder.path}/money.db');
    final database = const DatabaseOpener().open(file, key);
    await SettingsRepository(database).save(SettingKey.currency, 'JMD');
    final backup = File('${folder.path}/backup.db');
    await const DatabaseOpener().copyTo(database, backup);
    await database.close();
    expect(const DatabaseOpener().opensWith(backup, key), isTrue);
    expect(const DatabaseOpener().opensWith(backup, otherKey), isFalse);
  });
}
