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
      title: 'Breakfast Reminder',
      body: 'Good morning! It\'s time for a nutritious breakfast to start your day.',
      hour: 8,
      minute: 0,
    );

    await _scheduleMealReminder(
      id: 2,
      title: 'Lunch Reminder',
      body: 'Time for lunch! Maintain your nutrition plan with a balanced meal.',
      hour: 13,
      minute: 30,
    );

    await _scheduleMealReminder(
      id: 3,
      title: 'Dinner Reminder',
      body: 'Evening meal time. Follow your personalized nutrition recommendations.',
      hour: 19,
      minute: 30,
    );

    await _scheduleMealReminder(
      id: 4,
      title: 'Hydration Reminder',
      body: 'Stay hydrated throughout the day. Drink a glass of water.',
      hour: 10,
      minute: 0,
    );

    await _scheduleMealReminder(
      id: 5,
      title: 'Hydration Reminder',
      body: 'Remember to maintain proper hydration for optimal health.',
      hour: 15,
      minute: 0,
    );

    await _scheduleMealReminder(
      id: 6,
      title: 'Snack Reminder',
      body: 'Time for a healthy snack. Check your nutrition recommendations.',
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
      'Daily Progress Tracking',
      'Take a moment to log your meals and review your daily nutrition progress.',
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
      'Incorporate colorful vegetables into your meals for essential vitamins and minerals.',
      'Maintain proper hydration by drinking 8-10 glasses of water daily.',
      'Include lean protein sources in your meals to support recovery and maintain strength.',
      'Choose whole, natural foods over processed options for better nutrition.',
      'Consider eating smaller, more frequent meals to help manage treatment side effects.',
      'Green leafy vegetables contain antioxidants that support your immune system.',
      'Berries are rich in antioxidants and beneficial for overall health.',
    ];

    final random = DateTime.now().day % healthTips.length;

    await _notifications.zonedSchedule(
      20,
      'Daily Nutrition Tip',
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

