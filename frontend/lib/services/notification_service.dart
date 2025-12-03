import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_notifications',
          'Instant Notifications',
          channelDescription: 'Immediate notifications for important updates',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          subtitle: body,
        ),
      ),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> scheduleMealReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final enableMealReminders = prefs.getBool('meal_reminders') ?? true;
    
    if (!enableMealReminders) return;

    await _scheduleMealReminder(
      id: 1,
      title: '🍳 Breakfast Time!',
      body: 'Time for a healthy breakfast! Check your nutrition plan.',
      hour: 8,
      minute: 0,
    );

    await _scheduleMealReminder(
      id: 2,
      title: '🍽️ Lunch Reminder',
      body: 'Don\'t forget your lunch! Stay on track with your diet plan.',
      hour: 12,
      minute: 30,
    );

    await _scheduleMealReminder(
      id: 3,
      title: '🍲 Dinner Time',
      body: 'Time for dinner! Follow your personalized meal plan.',
      hour: 19,
      minute: 0,
    );

    await _scheduleMealReminder(
      id: 4,
      title: '💧 Hydration Reminder',
      body: 'Stay hydrated! Drink a glass of water.',
      hour: 10,
      minute: 0,
    );

    await _scheduleMealReminder(
      id: 5,
      title: '💧 Hydration Reminder',
      body: 'Remember to drink water for better health!',
      hour: 15,
      minute: 0,
    );

    await _scheduleMealReminder(
      id: 6,
      title: '🍎 Healthy Snack Time',
      body: 'Time for a healthy snack! Check your recommendations.',
      hour: 16,
      minute: 30,
    );
  }

  Future<void> _scheduleMealReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'meal_reminders',
          'Meal Reminders',
          channelDescription: 'Notifications for meal times and diet tracking',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          subtitle: body,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleDailyProgressReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final enableProgressReminders = prefs.getBool('progress_reminders') ?? true;
    
    if (!enableProgressReminders) return;

    await _notifications.zonedSchedule(
      10,
      '📊 Track Your Progress',
      'Don\'t forget to log your meals and track your daily progress!',
      _nextInstanceOfTime(20, 0),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'progress_reminders',
          'Progress Reminders',
          channelDescription: 'Daily reminders to track your progress',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
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
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleHealthTipNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final enableHealthTips = prefs.getBool('health_tips') ?? true;
    
    if (!enableHealthTips) return;

    final healthTips = [
      'Include colorful vegetables in your diet for essential nutrients.',
      'Stay hydrated! Aim for 8 glasses of water daily.',
      'Protein is essential for recovery. Include lean proteins in meals.',
      'Avoid processed foods and opt for whole, natural foods.',
      'Small, frequent meals can help manage side effects better.',
      'Green leafy vegetables are packed with cancer-fighting antioxidants.',
      'Berries are rich in antioxidants that support immune health.',
    ];

    final random = DateTime.now().day % healthTips.length;

    await _notifications.zonedSchedule(
      20,
      '💡 Daily Health Tip',
      healthTips[random],
      _nextInstanceOfTime(9, 0),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'health_tips',
          'Health Tips',
          channelDescription: 'Daily health and nutrition tips',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          playSound: true,
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
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleAllNotifications() async {
    await scheduleMealReminders();
    await scheduleDailyProgressReminder();
    await scheduleHealthTipNotification();
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
      NotificationDetails(
        android: AndroidNotificationDetails(
          'diet_reminders',
          'Diet Reminders',
          channelDescription: 'Reminders for diet recommendations',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
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

