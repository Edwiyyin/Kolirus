import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static const String _expiryChannelId = 'expiry_channel_v2';
  static const String _expiryChannelName = 'Food Expirations';
  static const String _generalChannelId = 'general_channel_v2';
  static const String _generalChannelName = 'General Alerts';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    // Explicitly create channels for reliability
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      _expiryChannelId,
      _expiryChannelName,
      importance: Importance.max,
      description: 'Notifications for food about to expire',
    ));
    
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      _generalChannelId,
      _generalChannelName,
      importance: Importance.high,
    ));

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    _initialized = true;
  }

  Future<void> cancelExpiryReminders(String itemId) async {
    await _notifications.cancel(_notifId(itemId, suffix: '5d'));
    await _notifications.cancel(_notifId(itemId, suffix: '1d'));
  }

  Future<void> scheduleExpiryReminder(
      String itemId, String name, DateTime expiryDate) async {
    await cancelExpiryReminders(itemId);

    final now = DateTime.now();
    // Use 9 AM for reminders
    final baseTime = DateTime(expiryDate.year, expiryDate.month, expiryDate.day, 9, 0);

    // 5-day warning
    final fiveDayDate = baseTime.subtract(const Duration(days: 5));
    if (fiveDayDate.isAfter(now)) {
      await _scheduleOne(
        id: _notifId(itemId, suffix: '5d'),
        title: 'Expiry in 5 Days',
        body: '$name will expire soon (${_fmt(expiryDate)}).',
        channelId: _expiryChannelId,
        scheduledDate: fiveDayDate,
      );
    }

    // 1-day warning
    final oneDayDate = baseTime.subtract(const Duration(days: 1));
    if (oneDayDate.isAfter(now)) {
      await _scheduleOne(
        id: _notifId(itemId, suffix: '1d'),
        title: 'Expiry Tomorrow!',
        body: '$name expires tomorrow! Use it today.',
        channelId: _expiryChannelId,
        scheduledDate: oneDayDate,
      );
    }
  }

  Future<void> showTestNotification({
    String title = 'Test Notification',
    String body = 'Kolirus notifications are working!',
  }) async {
    await _notifications.show(
      99999,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _generalChannelId,
          _generalChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
    );
  }

  Future<void> scheduleTestExpiryIn5Seconds() async {
    final scheduledDate = DateTime.now().add(const Duration(seconds: 5));
    await _scheduleOne(
      id: 88888,
      title: 'Dev Test: Expiry Reminder',
      body: 'This is what an expiry alert looks like.',
      channelId: _expiryChannelId,
      scheduledDate: scheduledDate,
    );
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<void> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required DateTime scheduledDate,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  int _notifId(String itemId, {required String suffix}) =>
      '${itemId}_$suffix'.hashCode.abs() % 2147483647;

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}