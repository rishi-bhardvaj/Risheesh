import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final db = ref.watch(databaseProvider);
  return NotificationService(db);
});

class NotificationService {
  final AppDatabase db;
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static void Function(String route)? onNotificationTapped;

  NotificationService(this.db);

  static Future<void> initialize({void Function(String route)? onRouteSelected}) async {
    if (_initialized) return;
    onNotificationTapped = onRouteSelected;

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open notification');

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    try {
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty && onNotificationTapped != null) {
            onNotificationTapped!(payload);
          }
        },
      );

      // Create channels on Android
      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          await _createChannels(androidImpl);
        }
      }

      _initialized = true;
    } catch (e) {
      debugPrint('[NotificationService] Initialization error: $e');
    }
  }

  static Future<void> _createChannels(AndroidFlutterLocalNotificationsPlugin impl) async {
    const adminChannel = AndroidNotificationChannel(
      'admin_alerts',
      'Admin Alerts',
      description: 'Alerts for user registrations and access permissions',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const jobsChannel = AndroidNotificationChannel(
      'jobs',
      'Matching Jobs',
      description: 'Notifications for new top-matching job opportunities',
      importance: Importance.high,
      playSound: true,
    );

    const leadsChannel = AndroidNotificationChannel(
      'leads',
      'Freelance Leads',
      description: 'Notifications for discovered high-value freelance leads',
      importance: Importance.defaultImportance,
    );

    const habitsChannel = AndroidNotificationChannel(
      'habits',
      'Daily Habits',
      description: 'Reminders for daily habits and reflections',
      importance: Importance.defaultImportance,
    );

    const leetcodeChannel = AndroidNotificationChannel(
      'leetcode',
      'DSA Problem of the Day',
      description: 'Daily algorithmic problem challenges',
      importance: Importance.defaultImportance,
    );

    await impl.createNotificationChannel(adminChannel);
    await impl.createNotificationChannel(jobsChannel);
    await impl.createNotificationChannel(leadsChannel);
    await impl.createNotificationChannel(habitsChannel);
    await impl.createNotificationChannel(leetcodeChannel);
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await androidImpl?.requestNotificationsPermission() ?? false;
    } else if (Platform.isIOS || Platform.isMacOS) {
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await iosImpl?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return false;
  }

  /// Sends an Admin notification when a new user registers and awaits permission approval.
  Future<void> notifyAdminNewUser({
    required String userId,
    required String name,
    String? email,
  }) async {
    final key = 'new_user_$userId';
    final alreadySent = await db.hasNotificationBeenSent(key);
    if (alreadySent) return;

    final title = 'New User Registration: $name';
    final body = '$name (${email ?? "No email"}) requested access to Risheesh services.';
    const route = '/settings/admin-users';

    await db.recordNotification(key, title, body, route: route, channel: 'admin_alerts');

    try {
      const androidDetails = AndroidNotificationDetails(
        'admin_alerts',
        'Admin Alerts',
        channelDescription: 'Alerts for user registrations and access permissions',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
      );
      const notificationDetails = NotificationDetails(android: androidDetails);

      await _plugin.show(
        userId.hashCode.abs() % 100000,
        title,
        body,
        notificationDetails,
        payload: route,
      );
    } catch (e) {
      debugPrint('[NotificationService] Failed to show admin notification: $e');
    }
  }

  /// Sends a notification for top matching jobs.
  Future<void> notifyMatchingJobs({
    required int count,
    required String topTitle,
    required String company,
    required int topScore,
  }) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final key = 'jobs_match_${today}_$count';
    final alreadySent = await db.hasNotificationBeenSent(key);
    if (alreadySent) return;

    final title = '$count new jobs match your profile';
    final body = '$topTitle at $company ($topScore% match)';
    const route = '/career';

    await db.recordNotification(key, title, body, route: route, channel: 'jobs');

    try {
      const androidDetails = AndroidNotificationDetails(
        'jobs',
        'Matching Jobs',
        channelDescription: 'Notifications for new top-matching job opportunities',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
      );
      const notificationDetails = NotificationDetails(android: androidDetails);

      await _plugin.show(
        101,
        title,
        body,
        notificationDetails,
        payload: route,
      );
    } catch (e) {
      debugPrint('[NotificationService] Failed to show job notification: $e');
    }
  }

  /// Sends an evening habit reminder if habits are still incomplete today.
  Future<void> checkAndNotifyHabits() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final key = 'habit_reminder_$today';
    final alreadySent = await db.hasNotificationBeenSent(key);
    if (alreadySent) return;

    final habits = await db.getActiveHabits();
    if (habits.isEmpty) return;

    // Check how many are completed today
    final startOfDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final logs = await db.getHabitLogsSince(startOfDay);
    final completedCount = logs.length;

    if (completedCount < habits.length) {
      final remaining = habits.length - completedCount;
      final title = 'Daily Habits: $remaining left today';
      const body = 'Stay consistent! Check off your habits before the day ends.';
      const route = '/track';

      await db.recordNotification(key, title, body, route: route, channel: 'habits');

      try {
        const androidDetails = AndroidNotificationDetails(
          'habits',
          'Daily Habits',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/launcher_icon',
        );
        await _plugin.show(
          102,
          title,
          body,
          const NotificationDetails(android: androidDetails),
          payload: route,
        );
      } catch (_) {}
    }
  }

  /// Shows a notification for DSA problem of the day.
  Future<void> notifyDsaProblem({
    required String title,
    required String difficulty,
  }) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final key = 'dsa_daily_$today';
    final alreadySent = await db.hasNotificationBeenSent(key);
    if (alreadySent) return;

    final notifTitle = 'DSA Daily Problem: $title';
    final body = 'Challenge yourself today with this $difficulty problem.';
    const route = '/track';

    await db.recordNotification(key, notifTitle, body, route: route, channel: 'leetcode');

    try {
      const androidDetails = AndroidNotificationDetails(
        'leetcode',
        'DSA Problem of the Day',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/launcher_icon',
      );
      await _plugin.show(
        103,
        notifTitle,
        body,
        const NotificationDetails(android: androidDetails),
        payload: route,
      );
    } catch (_) {}
  }
}
