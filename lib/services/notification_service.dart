import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static const String _expiryChannelId = 'expiry_channel';
  static const String _expiryChannelName = 'Expirations';
  static const String _generalChannelId = 'general_channel';
  static const String _generalChannelName = 'General';

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

    // Request Android 13+ permission
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    _initialized = true;
  }

  // ── Expiry reminders ───────────────────────────────────────────────────────

  Future<void> cancelExpiryReminders(String itemId) async {
    await _notifications.cancel(_notifId(itemId, suffix: '5d'));
    await _notifications.cancel(_notifId(itemId, suffix: '1d'));
  }

  Future<void> scheduleExpiryReminder(
      String itemId, String name, DateTime expiryDate) async {
    await cancelExpiryReminders(itemId);

    final now = DateTime.now();

    // 5-day warning
    final fiveDayDate = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day - 5,
      9, 0, 0,
    );
    if (fiveDayDate.isAfter(now)) {
      await _scheduleOne(
        id: _notifId(itemId, suffix: '5d'),
        title: 'Expiry in 5 Days',
        body: '$name expires on ${_fmt(expiryDate)} — use it soon!',
        channelId: _expiryChannelId,
        channelName: _expiryChannelName,
        scheduledDate: fiveDayDate,
      );
    }

    // 1-day warning
    final oneDayDate = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day - 1,
      9, 0, 0,
    );
    if (oneDayDate.isAfter(now)) {
      await _scheduleOne(
        id: _notifId(itemId, suffix: '1d'),
        title: 'Expiry Tomorrow!',
        body: '$name expires tomorrow (${_fmt(expiryDate)})!',
        channelId: _expiryChannelId,
        channelName: _expiryChannelName,
        scheduledDate: oneDayDate,
      );
    }
  }

  // ── Immediate test notification (for dev menu) ─────────────────────────────

  Future<void> showTestNotification({
    String title = 'Test Notification',
    String body = 'Kolirus notifications are working!',
  }) async {
    await _notifications.show(
      99999,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _generalChannelId,
          _generalChannelName,
          channelDescription: 'General Kolirus notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Schedule a notification 5 seconds from now (for dev testing)
  Future<void> scheduleTestExpiryIn5Seconds() async {
    final scheduledDate = DateTime.now().add(const Duration(seconds: 5));
    await _scheduleOne(
      id: 88888,
      title: 'Test Expiry Reminder',
      body: 'This is a test expiry notification from Kolirus dev menu.',
      channelId: _expiryChannelId,
      channelName: _expiryChannelName,
      scheduledDate: scheduledDate,
    );
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<void> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required DateTime scheduledDate,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    // If the computed time is in the past, skip silently
    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Reminders about food expiry dates',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
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