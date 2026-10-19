import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../security/lock_controller.dart';
import '../services/backup_service.dart';
import '../services/daily_upkeep.dart';
import '../services/notification_service.dart';
import 'database_session.dart';
import 'providers.dart';

/// Long-lived services created once at start-up and handed to the widget tree.
class AppServices {
  const AppServices({
    required this.session,
    required this.lock,
    required this.notifications,
    required this.restore,
  });

  final DatabaseSession session;
  final LockController lock;
  final NotificationService notifications;

  /// Swaps the live database for a backup and rebuilds the app on it.
  final Future<void> Function(BackupFile backup) restore;
}

final appServicesProvider = Provider<AppServices>(
  (ref) => throw StateError('App services are provided at start-up'),
);

final dailyUpkeepProvider = Provider<DailyUpkeep>((ref) {
  final services = ref.watch(appServicesProvider);
  return DailyUpkeep(
    database: ref.watch(databaseProvider),
    goals: ref.watch(goalRepositoryProvider),
    bills: ref.watch(billRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    backups: services.session.backups,
    notifications: services.notifications,
  );
});
