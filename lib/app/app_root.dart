import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../security/lock_controller.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../ui/home_shell.dart';
import '../ui/lock/lock_gate.dart';
import '../ui/theme/app_theme.dart';
import 'app_services.dart';
import 'database_session.dart';
import 'providers.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({
    super.key,
    required this.initialSession,
    required this.lock,
    required this.notifications,
  });

  final DatabaseSession initialSession;
  final LockController lock;
  final NotificationService notifications;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late DatabaseSession _session = widget.initialSession;

  Future<void> _restore(BackupFile backup) async {
    final restored = await _session.restore(backup);
    setState(() => _session = restored);
  }

  @override
  Widget build(BuildContext context) => ProviderScope(
        key: ObjectKey(_session),
        overrides: [
          databaseProvider.overrideWithValue(_session.database),
          appServicesProvider.overrideWithValue(AppServices(
            session: _session,
            lock: widget.lock,
            notifications: widget.notifications,
            restore: _restore,
          )),
        ],
        child: MoneyPathApp(lock: widget.lock),
      );
}

class MoneyPathApp extends ConsumerWidget {
  const MoneyPathApp({super.key, required this.lock});

  final LockController lock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    lock
      ..autoLockAfter = Duration(seconds: settings.autoLockSeconds)
      ..biometricsEnabled = settings.biometricsOn;
    return MaterialApp(
      title: 'Money Path',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      builder: (context, child) => LockGate(controller: lock, child: child!),
      home: const HomeShell(),
    );
  }
}
