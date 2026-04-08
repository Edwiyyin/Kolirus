import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Handles all local notifications for Kolirus.
///
/// IMPORTANT — for notifications to appear when the app is CLOSED:
/// AndroidManifest.xml must have:
///   <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
///   <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
///   <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
/// These are already present in the project.
///
/// On Android 13+ the user must also grant POST_NOTIFICATIONS permission,
/// which is requested at runtime via requestNotificationsPermission().
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const _expiryChannelId = 'kolirus_expiry_v4';
  static const _expiryChannelName = 'Food Expiry Reminders';
  static const _generalChannelId = 'kolirus_general_v4';
  static const _generalChannelName = 'General';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // Always recreate channels — ensures importance level is applied
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _expiryChannelId,
        _expiryChannelName,
        importance: Importance.max,
        description: 'Daily reminders for food about to expire',
        playSound: true,
        enableVibration: true,
        showBadge: true,
        enableLights: true,
      ),
    );

    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _generalChannelId,
        _generalChannelName,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    // Request runtime permissions (Android 13+ / API 33+)
    await androidImpl?.requestNotificationsPermission();
    // Request exact alarm permission (Android 12+ / API 31+)
    await androidImpl?.requestExactAlarmsPermission();

    _initialized = true;
  }

  // ── Expiry scheduling ──────────────────────────────────────────────────────

  Future<void> cancelExpiryReminders(String itemId) async {
    for (int day = 0; day <= 5; day++) {
      await _plugin.cancel(_notifId(itemId, 'd$day'));
    }
  }

  /// Schedule one notification at 9:00 AM for each of the 5 days leading up
  /// to (and including) the expiry date. Uses exactAllowWhileIdle so the
  /// notification fires even when the device is asleep and the app is closed.
  Future<void> scheduleExpiryReminder(
      String itemId,
      String itemName,
      DateTime expiryDate,
      ) async {
    await cancelExpiryReminders(itemId);

    final now = tz.TZDateTime.now(tz.local);

    for (int daysAhead = 0; daysAhead <= 5; daysAhead++) {
      final fireDate = tz.TZDateTime(
        tz.local,
        expiryDate.year,
        expiryDate.month,
        expiryDate.day,
        9,
        0,
      ).subtract(Duration(days: daysAhead));

      if (fireDate.isBefore(now)) continue;

      final title = daysAhead == 0
          ? 'Use $itemName TODAY'
          : daysAhead == 1
          ? '$itemName expires tomorrow'
          : '$itemName expires in $daysAhead days';

      final body = daysAhead == 0
          ? '$itemName expires today (${_fmt(expiryDate)}). Use it now!'
          : daysAhead == 1
          ? '$itemName expires tomorrow. Plan your meal today.'
          : '$itemName will expire on ${_fmt(expiryDate)} — $daysAhead days left.';

      await _scheduleNotification(
        id: _notifId(itemId, 'd$daysAhead'),
        title: title,
        body: body,
        channelId: _expiryChannelId,
        channelName: _expiryChannelName,
        fireAt: fireDate,
      );
    }
  }

  // ── Test helpers ───────────────────────────────────────────────────────────

  Future<void> showTestNotification({
    String title = 'Kolirus Test',
    String body = 'Notifications are working correctly!',
  }) async {
    await _plugin.show(
      99999,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _generalChannelId,
          _generalChannelName,
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
          ticker: title,
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> scheduleTestExpiryIn5Seconds() async {
    final fireAt =
    tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
    await _scheduleNotification(
      id: 88888,
      title: 'Dev: Expiry Test',
      body: 'This notification fired 5s after scheduling — works in background!',
      channelId: _expiryChannelId,
      channelName: _expiryChannelName,
      fireAt: fireAt,
    );
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() =>
      _plugin.pendingNotificationRequests();

  Future<void> cancelAll() => _plugin.cancelAll();

  // ── Core ───────────────────────────────────────────────────────────────────

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required tz.TZDateTime fireAt,
  }) async {
    if (fireAt.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      fireAt,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
          ticker: title,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: false,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      // exactAllowWhileIdle fires even in Doze mode (device asleep, app closed)
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  int _notifId(String itemId, String suffix) =>
      '${itemId}_$suffix'.hashCode.abs() % 2147483647;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}