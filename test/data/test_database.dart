import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:money_path/data/app_database.dart';

AppDatabase openTestDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}
