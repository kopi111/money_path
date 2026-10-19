import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminders/reminder_planner.dart';

/// Wraps the local notifications plugin: every reminder is rebuilt from the
/// data each time it changes, so no stale reminder survives an edit.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const _remindersChannel = AndroidNotificationDetails(
    'reminders',
    'Reminders',
    channelDescription: 'Deposit reminders and bill due dates',
    importance: Importance.defaultImportance,
  );
  static const _warningsChannel = AndroidNotificationDetails(
    'goal_warnings',
    'Goal warnings',
    channelDescription: 'When a goal falls behind',
    importance: Importance.high,
  );
  static const _firstWarningId = 10000;

  Future<void> start() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(requestAlertPermission: false),
      ),
    );
    _ready = true;
  }

  Future<void> askPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> replaceScheduled(List<PlannedReminder> reminders) async {
    await start();
    await _plugin.cancelAllPendingNotifications();
    for (final (index, reminder) in reminders.indexed) {
      await _plugin.zonedSchedule(
        id: index,
        scheduledDate: tz.TZDateTime(
          tz.local,
          reminder.day.year,
          reminder.day.month,
          reminder.day.day,
          reminder.hour,
        ),
        notificationDetails: const NotificationDetails(android: _remindersChannel),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: reminder.title,
        body: reminder.body,
      );
    }
  }

  Future<void> cancelAll() async {
    await start();
    await _plugin.cancelAll();
  }

  Future<void> warnGoalBehind({required int slot, required String title, required String body}) async {
    await start();
    await _plugin.show(
      id: _firstWarningId + slot,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: _warningsChannel),
    );
  }
}
