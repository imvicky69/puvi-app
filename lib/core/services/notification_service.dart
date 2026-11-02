import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service responsible for managing local notifications, custom notification channels,
/// and playing the custom intimate melody (`music.mp3`) on Android.
abstract final class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String customSoundChannelId = 'custom_sound_channel';
  static const String loveChannelId = 'puvi_love_channel_v2';
  static const String chatChannelId = 'puvi_chat_v2';

  static bool _isInitialized = false;

  static bool get _isTesting {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return true;
    }
  }

  /// Initializes the local notifications plugin and creates the custom sound channels on Android.
  static Future<void> initialize() async {
    if (_isTesting || _isInitialized) return;

    try {
      const androidInitSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const darwinInitSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidInitSettings,
        iOS: darwinInitSettings,
        macOS: darwinInitSettings,
      );

      await _localNotificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint(
            '[NotificationService] Notification tapped with payload: ${response.payload}',
          );
        },
      );

      final androidImplementation = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        // 1. Primary custom sound channel mapping explicitly to @raw/music
        const customChannel = AndroidNotificationChannel(
          customSoundChannelId,
          'Puvi Love Melody',
          description: 'Intimate alerts and love pings with our melody',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('music'),
          playSound: true,
          enableVibration: true,
          enableLights: true,
        );

        // 2. Love notes and pings channel (v2)
        const loveChannel = AndroidNotificationChannel(
          loveChannelId,
          'Puvi Love Notes & Pings',
          description: 'Instant love showers, sweet pings and mood updates',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('music'),
          playSound: true,
          enableVibration: true,
          enableLights: true,
        );

        // 3. Couple chat channel (v2)
        const chatChannel = AndroidNotificationChannel(
          chatChannelId,
          'Puvi Couple Chat',
          description: 'Private love messages, photos, hugs and kisses',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('music'),
          playSound: true,
          enableVibration: true,
          enableLights: true,
        );

        await androidImplementation.createNotificationChannel(customChannel);
        await androidImplementation.createNotificationChannel(loveChannel);
        await androidImplementation.createNotificationChannel(chatChannel);
      }

      _isInitialized = true;
      debugPrint(
        '[NotificationService] ✓ Successfully initialized custom sound channels.',
      );
    } catch (e) {
      debugPrint(
        '[NotificationService] Notice: Could not initialize notification channels: $e',
      );
    }
  }

  /// Displays a heads-up notification with the custom intimate melody (`music.mp3`).
  static Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
    String channelId = customSoundChannelId,
  }) async {
    if (_isTesting) return;

    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == chatChannelId
            ? 'Puvi Couple Chat'
            : channelId == loveChannelId
            ? 'Puvi Love Notes & Pings'
            : 'Puvi Love Melody',
        channelDescription: 'Intimate alerts and love pings with our melody',
        importance: Importance.max,
        priority: Priority.high,
        sound: const RawResourceAndroidNotificationSound('music'),
        playSound: true,
        enableVibration: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          sound: 'music.caf',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _localNotificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint(
        '[NotificationService] Notice: Could not display local notification: $e',
      );
    }
  }
}
