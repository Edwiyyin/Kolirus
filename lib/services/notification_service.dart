import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }
//test
  Future<void> scheduleExpiryReminder(String id, String name, DateTime expiryDate) async {
    // Remind 1 day before expiry at 9 AM
    final scheduledDate = expiryDate.subtract(const Duration(days: 1));
    final finalDate = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day, 9);

    if (finalDate.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      id.hashCode,
      'Food Expiry Reminder',
      'Your $name is about to expire tomorrow!',
      tz.TZDateTime.from(finalDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails('expiry_channel', 'Expirations',
            importance: Importance.high, priority: Priority.high),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
