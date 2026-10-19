import 'package:drift/drift.dart';


import '../../domain/money/currency.dart';
import '../app_database.dart';
import 'table_watch.dart';

/// The owner's preferences, read as one immutable value.
class AppSettings {
  const AppSettings({
    required this.currency,
    required this.amberThresholdPercent,
    required this.autoLockSeconds,
    required this.remindersOn,
    required this.biometricsOn,
    required this.billReminderDays,
  });

  static const defaults = AppSettings(
    currency: Currency.jamaicanDollar,
    amberThresholdPercent: 25,
    autoLockSeconds: 60,
    remindersOn: true,
    biometricsOn: false,
    billReminderDays: 2,
  );

  final Currency currency;
  final int amberThresholdPercent;
  final int autoLockSeconds;
  final bool remindersOn;
  final bool biometricsOn;
  final int billReminderDays;
}

enum SettingKey { currency, amberThresholdPercent, autoLockSeconds, remindersOn, biometricsOn, billReminderDays }

class SettingsRepository {
  SettingsRepository(this._database);

  final AppDatabase _database;

  Stream<AppSettings> watch() => watchTables(_database, [_database.settings], load);

  Future<AppSettings> load() async {
    final rows = await _database.select(_database.settings).get();
    final stored = {for (final row in rows) row.key: row.value};
    const fallback = AppSettings.defaults;
    int number(SettingKey key, int otherwise) => int.tryParse(stored[key.name] ?? '') ?? otherwise;
    bool flag(SettingKey key, bool otherwise) => (stored[key.name] ?? '$otherwise') == 'true';
    return AppSettings(
      currency: Currency.fromCode(stored[SettingKey.currency.name] ?? fallback.currency.code),
      amberThresholdPercent: number(SettingKey.amberThresholdPercent, fallback.amberThresholdPercent),
      autoLockSeconds: number(SettingKey.autoLockSeconds, fallback.autoLockSeconds),
      remindersOn: flag(SettingKey.remindersOn, fallback.remindersOn),
      biometricsOn: flag(SettingKey.biometricsOn, fallback.biometricsOn),
      billReminderDays: number(SettingKey.billReminderDays, fallback.billReminderDays),
    );
  }

  /// True the first time [marker] is claimed, false ever after. Used so a
  /// warning is sent once rather than on every launch.
  Future<bool> claimOnce(String marker) async {
    final inserted = await _database.into(_database.settings).insert(
          SettingsCompanion.insert(key: 'once:$marker', value: 'claimed'),
          mode: InsertMode.insertOrIgnore,
        );
    return inserted > 0;
  }

  Future<void> save(SettingKey key, Object value) async {
    await _database.into(_database.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(key: key.name, value: '$value'),
        );
  }
}
