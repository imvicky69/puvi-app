import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'love_stats_service.dart';

/// Service for safely managing and synchronizing FCM device tokens to Firestore.
abstract final class FcmTokenService {
  static const String pujaUid = 'HfzubbPMBsgQugeC5AcNqyWbwlw2';
  static const String vickyUid = 'bx3PgTysxeX7HMfkyPWiCwtqLZG3';

  static bool _hasInitializedRefreshListener = false;

  /// Determines the verified UID for the user name or email.
  static String? getUserId({required String userName, String? email}) {
    final lowerName = userName.trim().toLowerCase();
    final lowerEmail = (email ?? '').trim().toLowerCase();

    if (lowerName == 'puja' || lowerEmail.contains('puja')) {
      return pujaUid;
    } else if (lowerName == 'vicky' || lowerEmail.contains('vicky')) {
      return vickyUid;
    }
    return null;
  }

  static bool get _isTesting {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return true;
    }
  }

  /// Safely synchronizes the current device's FCM token to Firestore `users/{userId}`.
  ///
  /// Guarantees:
  /// - Non-blocking: will never prevent or delay the user's login.
  /// - Safe in unit/widget test environments.
  /// - Safe if offline, permission denied, or on unsupported platforms.
  static Future<void> syncUserFcmToken({
    required String userName,
    String? email,
  }) async {
    // 1. Guard against test runner environments
    if (_isTesting) return;

    // 2. Guard against uninitialized Firebase
    if (Firebase.apps.isEmpty) {
      debugPrint(
        '[FcmTokenService] Firebase not initialized. Skipping FCM sync.',
      );
      return;
    }

    final uid = getUserId(userName: userName, email: email);
    if (uid == null) {
      debugPrint('[FcmTokenService] Unrecognized user name: $userName');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      // 3. Request permissions safely (iOS / Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: true,
      );

      debugPrint(
        '[FcmTokenService] Notification authorization: ${settings.authorizationStatus}',
      );

      // 4. Listen for registered / refreshed tokens
      if (!_hasInitializedRefreshListener) {
        _hasInitializedRefreshListener = true;
        messaging.onRegistered.listen((newToken) {
          if (newToken.isNotEmpty) {
            _saveTokenToFirestore(uid, newToken, userName);
          }
        });
        // ignore: deprecated_member_use
        messaging.onTokenRefresh.listen((newToken) {
          if (newToken.isNotEmpty) {
            _saveTokenToFirestore(uid, newToken, userName);
          }
        });
      }

      // 5. Trigger device registration
      try {
        await messaging.register();
      } catch (regErr) {
        debugPrint('[FcmTokenService] Notice during register(): $regErr');
      }

      // 6. Direct fallback token retrieval (legacy fallback)
      try {
        // ignore: deprecated_member_use
        final token = await messaging.getToken();
        if (token != null && token.isNotEmpty) {
          await _saveTokenToFirestore(uid, token, userName);
        }
      } catch (tokenErr) {
        // When firebase_messaging_installation_id_enabled is true, Firebase
        // disables legacy getToken() in favor of register() / onRegistered.
        // We log only unexpected errors.
        if (!tokenErr.toString().contains('API disabled')) {
          debugPrint('[FcmTokenService] Notice during getToken(): $tokenErr');
        }
      }
    } catch (e) {
      // Intentionally silent catch to ensure login flow is never broken
      debugPrint('[FcmTokenService] Notice: Could not sync FCM token: $e');
    }
  }

  static bool _hasInitializedNotificationListeners = false;

  /// Sets up FCM message opened handlers and foreground push listeners
  /// so that tapping a love push notification or receiving it in foreground
  /// triggers the love shower animation and melody.
  static void initializeNotificationHandling() {
    if (_isTesting ||
        Firebase.apps.isEmpty ||
        _hasInitializedNotificationListeners) {
      return;
    }
    _hasInitializedNotificationListeners = true;

    try {
      final messaging = FirebaseMessaging.instance;

      // 1. App opened from background by tapping notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleLoveNotificationData(message.data);
      });

      // 2. App opened from terminated/killed state by tapping notification
      messaging.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          _handleLoveNotificationData(message.data);
        }
      });

      // 3. Foreground notification received
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleLoveNotificationData(message.data);
      });
    } catch (e) {
      debugPrint(
        '[FcmTokenService] Notice initializing notification handling: $e',
      );
    }
  }

  static void _handleLoveNotificationData(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    final type = data['type'];
    if (type == 'love_update' || type == 'ping') {
      final increment =
          int.tryParse(data['increment']?.toString() ?? '') ??
          (data['isMegaShower'] == 'true' ? 1000 : 1);
      final isMegaShower = data['isMegaShower'] == 'true' || increment >= 1000;
      final senderName = data['senderName']?.toString();

      LoveStatsService.triggerLoveCelebration(
        increment: increment,
        senderName: senderName,
        isMegaShower: isMegaShower,
      );
    }
  }

  static Future<void> _saveTokenToFirestore(
    String uid,
    String token,
    String userName,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(uid).set({
        'fcmToken': token,
        'name': userName,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint(
        '[FcmTokenService] ✓ Successfully synced FCM token for $userName ($uid)',
      );
    } catch (e) {
      debugPrint(
        '[FcmTokenService] Notice: Failed to write token to Firestore: $e',
      );
    }
  }
}
