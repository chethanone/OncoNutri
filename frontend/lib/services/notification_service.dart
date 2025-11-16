import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleDietReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'diet_reminders',
          'Diet Reminders',
          channelDescription: 'Reminders for diet recommendations',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleBreakfastReminder() async {
    final now = DateTime.now();
    final scheduledTime = DateTime(now.year, now.month, now.day, 8, 0);

    await scheduleDietReminder(
      id: 1,
      title: 'Breakfast Reminder',
      body: 'Time for a healthy breakfast! Check your recommendations.',
      scheduledTime: scheduledTime.isAfter(now)
          ? scheduledTime
          : scheduledTime.add(const Duration(days: 1)),
    );
  }

  Future<void> scheduleLunchReminder() async {
    final now = DateTime.now();
    final scheduledTime = DateTime(now.year, now.month, now.day, 13, 0);

    await scheduleDietReminder(
      id: 2,
      title: 'Lunch Reminder',
      body: 'Time for lunch! Check your personalized meal plan.',
      scheduledTime: scheduledTime.isAfter(now)
          ? scheduledTime
          : scheduledTime.add(const Duration(days: 1)),
    );
  }

  Future<void> scheduleDinnerReminder() async {
    final now = DateTime.now();
    final scheduledTime = DateTime(now.year, now.month, now.day, 19, 0);

    await scheduleDietReminder(
      id: 3,
      title: 'Dinner Reminder',
      body: 'Time for dinner! Follow your recommended diet plan.',
      scheduledTime: scheduledTime.isAfter(now)
          ? scheduledTime
          : scheduledTime.add(const Duration(days: 1)),
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}
