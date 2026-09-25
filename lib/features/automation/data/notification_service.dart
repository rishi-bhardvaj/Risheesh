import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/database/app_database.dart';
import '../domain/automation_models.dart';

class SentNotificationItem {
  final int id;
  final String title;
  final String body;
  final NotificationCategory category;
  final String? payload;
  final DateTime timestamp;

  const SentNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    this.payload,
    required this.timestamp,
  });
}

class AppNotificationService {
  static final AppNotificationService _instance = AppNotificationService._internal();
  factory AppNotificationService() => _instance;
  AppNotificationService._internal();

  FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
  final List<SentNotificationItem> _recentNotifications = [];

  List<SentNotificationItem> get recentNotifications => List.unmodifiable(_recentNotifications);

  Future<void> initialize({void Function(String?)? onSelectNotification}) async {
    try {
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      );

      await _flutterLocalNotificationsPlugin?.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (onSelectNotification != null) {
            onSelectNotification(response.payload);
          }
        },
      );
    } catch (_) {
      // Platform channels not available in standard unit tests or desktop
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final androidImplementation = _flutterLocalNotificationsPlugin
          ?.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidImplementation?.requestNotificationsPermission();
      return granted ?? true;
    } catch (_) {
      return true;
    }
  }

  bool isCategoryEnabled(NotificationCategory category, NotificationSetting? settings) {
    if (settings == null) return true;
    switch (category) {
      case NotificationCategory.career:
        return settings.careerEnabled;
      case NotificationCategory.work:
        return settings.workEnabled;
      case NotificationCategory.dsa:
        return settings.dsaEnabled;
      case NotificationCategory.freelance:
        return settings.freelanceEnabled;
      case NotificationCategory.projects:
        return settings.projectsEnabled;
      case NotificationCategory.weeklySummary:
        return settings.weeklyReportsEnabled;
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required NotificationCategory category,
    NotificationSetting? settings,
    String? payload,
  }) async {
    // 1. Check user preference settings
    if (!isCategoryEnabled(category, settings)) {
      return;
    }

    // 2. Record to in-memory notification log
    _recentNotifications.insert(
      0,
      SentNotificationItem(
        id: id,
        title: title,
        body: body,
        category: category,
        payload: payload,
        timestamp: DateTime.now(),
      ),
    );
    if (_recentNotifications.length > 50) {
      _recentNotifications.removeLast();
    }

    // 3. Dispatch native platform notification
    try {
      const androidDetails = AndroidNotificationDetails(
        'career_os_main_channel',
        'Career OS Notifications',
        channelDescription: 'Proactive reminders, deadlines, and matches for Career OS',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin?.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (_) {
      // Safely ignore if native channels fail
    }
  }

  Future<void> cancelAll() async {
    try {
      await _flutterLocalNotificationsPlugin?.cancelAll();
    } catch (_) {}
  }
}
