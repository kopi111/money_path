import 'package:flutter/material.dart';

import 'app/app_root.dart';
import 'app/database_session.dart';
import 'security/biometric_gate.dart';
import 'security/lock_controller.dart';
import 'security/secret_store.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final secrets = SecretStore();
  final session = await DatabaseSession.open(secrets);
  final lock = LockController(secrets: secrets, biometrics: BiometricGate());
  await lock.start();
  runApp(AppRoot(initialSession: session, lock: lock, notifications: NotificationService()));
}
