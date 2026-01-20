import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import '../models/affirmation.dart';
import 'affirmation_service.dart';

/// Background task name for affirmation notifications
const String affirmationTaskName = 'affirmationNotificationTask';

/// Callback dispatcher for Workmanager (must be top-level function)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == affirmationTaskName) {
        await NotificationService.instance._showScheduledAffirmation();
      }
      return true;
    } catch (e) {
      debugPrint('Background task error: $e');
      return false;
    }
  });
}

/// Service for handling local push notifications for affirmations
class NotificationService {
  static final NotificationService instance = NotificationService._();

  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Notification channel details for Android
  static const AndroidNotificationChannel _morningChannel =
      AndroidNotificationChannel(
    'morning_affirmations',
    'Morning Affirmations',
    description: 'Daily morning affirmation notifications',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel _eveningChannel =
      AndroidNotificationChannel(
    'evening_affirmations',
    'Evening Affirmations',
    description: 'Daily evening affirmation notifications',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel _sleepTimerChannel =
      AndroidNotificationChannel(
    'sleep_timer_alarm',
    'Sleep Timer Alarm',
    description: 'Alarm notification when sleep timer completes',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
  );

  /// Notification IDs
  static const int morningNotificationId = 1001;
  static const int eveningNotificationId = 1002;
  static const int sleepTimerNotificationId = 2001;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Failed to get timezone: $e');
      // Fallback to UTC
      tz.setLocalLocation(tz.UTC);
    }

    // Initialize notification settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_morningChannel);
        await androidPlugin.createNotificationChannel(_eveningChannel);
        await androidPlugin.createNotificationChannel(_sleepTimerChannel);
      }
    }

    // Initialize Workmanager for background tasks
    if (!kIsWeb) {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
    }

    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Navigation will be handled by the app when it opens
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return false;
  }

  /// Schedule morning and evening affirmation notifications
  Future<void> scheduleAffirmationNotifications(
      AffirmationSettings settings) async {
    if (kIsWeb) {
      debugPrint('Notifications not supported on web');
      return;
    }

    // Cancel existing notifications first
    await cancelAllNotifications();

    // Save settings for background task
    await _saveNotificationSettings(settings);

    // Schedule morning notification
    if (settings.morningEnabled) {
      await _scheduleDailyNotification(
        id: morningNotificationId,
        title: '🌅 Good Morning!',
        body: 'Start your day with a positive affirmation',
        hour: settings.morningTime.hour,
        minute: settings.morningTime.minute,
        channelId: _morningChannel.id,
        channelName: _morningChannel.name,
        channelDescription: _morningChannel.description ?? '',
      );
      debugPrint(
          'Morning notification scheduled at ${settings.morningTime.hour}:${settings.morningTime.minute}');
    }

    // Schedule evening notification
    if (settings.eveningEnabled) {
      await _scheduleDailyNotification(
        id: eveningNotificationId,
        title: '🌙 Good Evening!',
        body: 'End your day with gratitude and reflection',
        hour: settings.eveningTime.hour,
        minute: settings.eveningTime.minute,
        channelId: _eveningChannel.id,
        channelName: _eveningChannel.name,
        channelDescription: _eveningChannel.description ?? '',
      );
      debugPrint(
          'Evening notification scheduled at ${settings.eveningTime.hour}:${settings.eveningTime.minute}');
    }

    // Also register background tasks for more reliable delivery
    await _registerBackgroundTasks(settings);
  }

  /// Schedule a daily notification at a specific time
  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) async {
    // Get the next occurrence of the specified time
    final scheduledTime = _nextInstanceOfTime(hour, minute);

    // Fetch a random affirmation for the notification body
    final affirmation = await _getRandomAffirmation();
    final notificationBody = affirmation?.text ?? body;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(notificationBody),
      category: AndroidNotificationCategory.reminder,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      notificationBody,
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode({
        'type': id == morningNotificationId ? 'morning' : 'evening',
        'affirmationId': affirmation?.id,
      }),
    );
  }

  /// Get the next occurrence of a specific time today or tomorrow
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

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Get a random affirmation for the notification
  Future<Affirmation?> _getRandomAffirmation() async {
    try {
      final affirmations = await AffirmationService.loadAffirmations();
      if (affirmations.isEmpty) {
        // Return a default affirmation if none exist
        return Affirmation(
          id: 'default',
          text:
              'You are capable of achieving great things. Believe in yourself!',
          type: AffirmationType.curated,
          category: AffirmationCategory.motivation,
          createdAt: DateTime.now(),
        );
      }

      // Prefer favorites, then random
      final favorites = affirmations.where((a) => a.isFavorite).toList();
      if (favorites.isNotEmpty) {
        favorites.shuffle();
        return favorites.first;
      }

      affirmations.shuffle();
      return affirmations.first;
    } catch (e) {
      debugPrint('Error getting affirmation: $e');
      return null;
    }
  }

  /// Register background tasks for more reliable notification delivery
  Future<void> _registerBackgroundTasks(AffirmationSettings settings) async {
    if (kIsWeb) return;

    // Cancel existing tasks
    await Workmanager().cancelAll();

    // Register periodic task to check and show notifications
    // This runs every 15 minutes (minimum interval on Android)
    await Workmanager().registerPeriodicTask(
      'affirmation_check',
      affirmationTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    debugPrint('Background task registered');
  }

  /// Show scheduled affirmation (called from background task)
  Future<void> _showScheduledAffirmation() async {
    final settings = await _loadNotificationSettings();
    if (settings == null) return;

    final now = TimeOfDay.now();
    final currentMinutes = now.hour * 60 + now.minute;

    // Check if it's morning notification time (within 15-minute window)
    if (settings.morningEnabled) {
      final morningMinutes =
          settings.morningTime.hour * 60 + settings.morningTime.minute;
      if ((currentMinutes - morningMinutes).abs() < 15) {
        await _showImmediateNotification(
          id: morningNotificationId,
          title: '🌅 Good Morning!',
          isMorning: true,
        );
      }
    }

    // Check if it's evening notification time (within 15-minute window)
    if (settings.eveningEnabled) {
      final eveningMinutes =
          settings.eveningTime.hour * 60 + settings.eveningTime.minute;
      if ((currentMinutes - eveningMinutes).abs() < 15) {
        await _showImmediateNotification(
          id: eveningNotificationId,
          title: '🌙 Good Evening!',
          isMorning: false,
        );
      }
    }
  }

  /// Show an immediate notification
  Future<void> _showImmediateNotification({
    required int id,
    required String title,
    required bool isMorning,
  }) async {
    final affirmation = await _getRandomAffirmation();
    final body = affirmation?.text ?? 'Take a moment to reflect on your day.';

    final channel = isMorning ? _morningChannel : _eveningChannel;

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _notifications.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode({
        'type': isMorning ? 'morning' : 'evening',
        'affirmationId': affirmation?.id,
      }),
    );
  }

  /// Save notification settings for background task access
  Future<void> _saveNotificationSettings(AffirmationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'notification_settings', jsonEncode(settings.toJson()));
  }

  /// Load notification settings in background task
  Future<AffirmationSettings?> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('notification_settings');
      if (json != null) {
        return AffirmationSettings.fromJson(jsonDecode(json));
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
    return null;
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    if (!kIsWeb) {
      await Workmanager().cancelAll();
    }
    debugPrint('All notifications cancelled');
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Show a test notification immediately
  Future<void> showTestNotification({bool isMorning = true}) async {
    await _showImmediateNotification(
      id: isMorning ? morningNotificationId : eveningNotificationId,
      title: isMorning ? '🌅 Good Morning!' : '🌙 Good Evening!',
      isMorning: isMorning,
    );
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }
    return true; // iOS handles this differently
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // ============== SLEEP TIMER ALARM METHODS ==============

  /// Schedule a sleep timer alarm notification
  /// This will fire even when the app is closed
  Future<void> scheduleSleepTimerAlarm(Duration duration) async {
    if (kIsWeb) {
      debugPrint('Sleep timer alarm not supported on web');
      return;
    }

    // Cancel any existing sleep timer alarm
    await cancelSleepTimerAlarm();

    // Calculate the exact time when alarm should fire
    final scheduledTime = tz.TZDateTime.now(tz.local).add(duration);

    // Save the scheduled time for reference
    await _saveSleepTimerAlarmTime(scheduledTime);

    const androidDetails = AndroidNotificationDetails(
      'sleep_timer_alarm',
      'Sleep Timer Alarm',
      channelDescription: 'Alarm notification when sleep timer completes',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      autoCancel: false,
      ongoing: true,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      sleepTimerNotificationId,
      '⏰ Sleep Timer Complete',
      'Your sleep timer has finished. Tap to dismiss.',
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({'type': 'sleep_timer_alarm'}),
    );

    debugPrint(
        'Sleep timer alarm scheduled for: $scheduledTime (in ${duration.inMinutes} minutes)');
  }

  /// Cancel the sleep timer alarm
  Future<void> cancelSleepTimerAlarm() async {
    await _notifications.cancel(sleepTimerNotificationId);
    await _clearSleepTimerAlarmTime();
    debugPrint('Sleep timer alarm cancelled');
  }

  /// Show immediate alarm notification (for when app is in foreground)
  Future<void> showSleepTimerAlarmNow() async {
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'sleep_timer_alarm',
      'Sleep Timer Alarm',
      channelDescription: 'Alarm notification when sleep timer completes',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      autoCancel: false,
      ongoing: true,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      sleepTimerNotificationId,
      '⏰ Sleep Timer Complete',
      'Your sleep timer has finished. Tap to dismiss.',
      details,
      payload: jsonEncode({'type': 'sleep_timer_alarm'}),
    );

    debugPrint('Sleep timer alarm notification shown');
  }

  /// Save sleep timer alarm time to SharedPreferences
  Future<void> _saveSleepTimerAlarmTime(tz.TZDateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sleep_timer_alarm_time', time.toIso8601String());
  }

  /// Get the scheduled sleep timer alarm time
  Future<DateTime?> getSleepTimerAlarmTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString('sleep_timer_alarm_time');
    if (timeStr != null) {
      try {
        return DateTime.parse(timeStr);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Clear saved sleep timer alarm time
  Future<void> _clearSleepTimerAlarmTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sleep_timer_alarm_time');
  }

  /// Check if sleep timer alarm is scheduled
  Future<bool> isSleepTimerAlarmScheduled() async {
    final pending = await _notifications.pendingNotificationRequests();
    return pending.any((n) => n.id == sleepTimerNotificationId);
  }
}
