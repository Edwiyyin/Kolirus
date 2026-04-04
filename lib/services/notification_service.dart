import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static const String _expiryChannelId   = 'expiry_channel';
  static const String _expiryChannelName = 'Expirations';

  Future<void> init() async {
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
    await _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Cancel all notifications for a given item id (clears both the 5-day
  /// and 1-day reminders that may have been scheduled before).
  Future<void> cancelExpiryReminders(String itemId) async {
    await _notifications.cancel(_notifId(itemId, suffix: '5d'));
    await _notifications.cancel(_notifId(itemId, suffix: '1d'));
  }

  /// Schedule two notifications for [itemId]:
  ///   • 5 days before expiry at 09:00  — "expires in 5 days"
  ///   • 1 day  before expiry at 09:00  — "expires tomorrow"
  Future<void> scheduleExpiryReminder(
      String itemId, String name, DateTime expiryDate) async {
    // Always cancel existing reminders first so we don't double-schedule.
    await cancelExpiryReminders(itemId);

    final now = DateTime.now();

    // ── 5-day warning ──────────────────────────────────────────────────────
    final fiveDayDate = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day - 5,
      9, 0, 0,
    );
    if (fiveDayDate.isAfter(now)) {
      await _scheduleOne(
        id: _notifId(itemId, suffix: '5d'),
        title: '⚠️ Expiry in 5 Days',
        body: '$name expires on ${_fmt(expiryDate)} — use it soon!',
        scheduledDate: fiveDayDate,
      );
    }

    // ── 1-day warning ──────────────────────────────────────────────────────
    final oneDayDate = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day - 1,
      9, 0, 0,
    );
    if (oneDayDate.isAfter(now)) {
      await _scheduleOne(
        id: _notifId(itemId, suffix: '1d'),
        title: '🚨 Expiry Tomorrow!',
        body: '$name expires tomorrow (${_fmt(expiryDate)})!',
        scheduledDate: oneDayDate,
      );
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  Future<void> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _expiryChannelId,
          _expiryChannelName,
          channelDescription: 'Reminders about food expiry dates',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
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

  /// Stable integer id derived from the item id string + a short suffix so
  /// the 5-day and 1-day notifications don't collide.
  int _notifId(String itemId, {required String suffix}) =>
      '${itemId}_$suffix'.hashCode.abs() % 2147483647;

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}