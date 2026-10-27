import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'fcm_token_service.dart';

/// Represents a real-time love update event (either tap or +1,000 mega shower)
/// received from the partner or via FCM push notification.
class LoveUpdateEvent {
  final int totalCount;
  final int increment;
  final String senderId;
  final String senderName;
  final bool isMegaShower;
  final DateTime timestamp;

  const LoveUpdateEvent({
    required this.totalCount,
    required this.increment,
    required this.senderId,
    required this.senderName,
    this.isMegaShower = false,
    required this.timestamp,
  });
}

/// Service responsible for real-time synchronization of shared couple stats
/// (such as total love taps, loveCountPuja, loveCountVicky, anniversary date)
/// directly to Cloud Firestore at `shared/stats` and `couples/puvi_couple`.
abstract final class LoveStatsService {
  static const String collectionName = 'shared';
  static const String docName = 'stats';
  static const String coupleCollectionName = 'couples';
  static const String coupleDocName = 'puvi_couple';

  static int _inMemoryLoveCount = 272000;
  static DateTime _togetherSince = DateTime(2026, 4, 11);

  static String? _currentUserId;
  static String? _currentUserName;
  static int? _lastProcessedCount;
  static DateTime? _lastLocalIncrementTime;
  static DateTime? _lastCelebrationTime;
  static int? _lastCelebrationIncrement;

  static final StreamController<LoveUpdateEvent> _partnerLoveController =
      StreamController<LoveUpdateEvent>.broadcast();

  /// Stream of love update events specifically sent by the partner in real-time
  /// or triggered when a love push notification is opened.
  static Stream<LoveUpdateEvent> get onPartnerLove =>
      _partnerLoveController.stream;

  /// Sets the currently active logged-in user to distinguish local vs partner updates.
  static void setCurrentUser(String userName) {
    _currentUserName = userName;
    _currentUserId = FcmTokenService.getUserId(userName: userName);
  }

  /// Returns the current in-memory love count (optimistic value).
  static int get currentLoveCount => _inMemoryLoveCount;

  /// Returns the current anniversary start date.
  static DateTime get togetherSince => _togetherSince;

  static bool get _isTesting {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return true;
    }
  }

  /// Dispatches a partner love celebration event with debouncing/deduplication.
  static void triggerLoveCelebration({
    required int increment,
    String? senderName,
    bool isMegaShower = false,
    int? totalCount,
  }) {
    final now = DateTime.now();
    if (_lastCelebrationTime != null &&
        _lastCelebrationIncrement == increment &&
        now.difference(_lastCelebrationTime!).inMilliseconds < 3000) {
      // Debounce duplicate events (e.g. both Firestore snapshot and FCM received)
      return;
    }
    _lastCelebrationTime = now;
    _lastCelebrationIncrement = increment;

    final resolvedSenderName =
        senderName ??
        (_currentUserName?.toLowerCase() == 'puja' ? 'Vicky' : 'Puja');

    _partnerLoveController.add(
      LoveUpdateEvent(
        totalCount: totalCount ?? _inMemoryLoveCount,
        increment: increment,
        senderId: FcmTokenService.getUserId(userName: resolvedSenderName) ?? '',
        senderName: resolvedSenderName,
        isMegaShower: isMegaShower || increment >= 1000,
        timestamp: now,
      ),
    );
  }

  /// Streams real-time love count directly from Firestore `shared/stats`.
  static Stream<int> watchLoveCount() {
    if (_isTesting || Firebase.apps.isEmpty) {
      return Stream.value(_inMemoryLoveCount);
    }

    try {
      return FirebaseFirestore.instance
          .collection(collectionName)
          .doc(docName)
          .snapshots()
          .map((snapshot) {
            if (!snapshot.exists || snapshot.data() == null) {
              return _inMemoryLoveCount;
            }
            final data = snapshot.data()!;
            final count = data['loveCount'];
            if (count is num) {
              final newCount = count.toInt();
              final diff = (_lastProcessedCount != null)
                  ? (newCount - _lastProcessedCount!)
                  : 0;
              final lastUpdatedBy = data['lastUpdatedBy'] as String?;

              // Check if this update came from our partner
              final isLocalRecent =
                  _lastLocalIncrementTime != null &&
                  DateTime.now()
                          .difference(_lastLocalIncrementTime!)
                          .inSeconds <
                      3;
              final isFromPartner =
                  (lastUpdatedBy != null && lastUpdatedBy != _currentUserId) ||
                  (!isLocalRecent && diff > 0);

              if (_lastProcessedCount != null && diff > 0 && isFromPartner) {
                final senderName = lastUpdatedBy == FcmTokenService.pujaUid
                    ? 'Puja'
                    : (lastUpdatedBy == FcmTokenService.vickyUid
                          ? 'Vicky'
                          : (_currentUserName?.toLowerCase() == 'puja'
                                ? 'Vicky'
                                : 'Puja'));

                triggerLoveCelebration(
                  increment: diff,
                  senderName: senderName,
                  isMegaShower: diff >= 1000,
                  totalCount: newCount,
                );
              }

              _lastProcessedCount = newCount;
              _inMemoryLoveCount = newCount;
            }

            final ts = data['togetherSince'];
            if (ts is String) {
              final parsed = DateTime.tryParse(ts);
              if (parsed != null) _togetherSince = parsed;
            }

            return _inMemoryLoveCount;
          })
          .handleError((error) {
            debugPrint('[LoveStatsService] watchLoveCount error: $error');
            return _inMemoryLoveCount;
          });
    } catch (e) {
      debugPrint('[LoveStatsService] Exception starting love count stream: $e');
      return Stream.value(_inMemoryLoveCount);
    }
  }

  /// Streams real-time anniversary date from Firestore.
  static Stream<DateTime> watchTogetherSince() {
    if (_isTesting || Firebase.apps.isEmpty) {
      return Stream.value(_togetherSince);
    }

    try {
      return FirebaseFirestore.instance
          .collection(collectionName)
          .doc(docName)
          .snapshots()
          .map((snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              final ts = snapshot.data()!['togetherSince'];
              if (ts is String) {
                final parsed = DateTime.tryParse(ts);
                if (parsed != null) {
                  _togetherSince = parsed;
                }
              }
            }
            return _togetherSince;
          })
          .handleError((error) {
            debugPrint('[LoveStatsService] watchTogetherSince error: $error');
            return _togetherSince;
          });
    } catch (e) {
      return Stream.value(_togetherSince);
    }
  }

  /// Increments love count in Firestore by [increment] (default 1, or 1000 for mega shower).
  ///
  /// Atomically increments:
  /// - `loveCount`: Total shared love count in both `shared/stats` and `couples/puvi_couple`.
  /// - `loveCountVicky` or `loveCountPuja`: The sender's individual contribution.
  /// - `lastUpdatedBy`: The sender's verified UID.
  /// - `lastUpdatedAt`: Server timestamp.
  static Future<void> incrementLove({
    required String userName,
    int increment = 1,
  }) async {
    _inMemoryLoveCount += increment;
    _lastProcessedCount = _inMemoryLoveCount;
    _lastLocalIncrementTime = DateTime.now();

    if (_isTesting || Firebase.apps.isEmpty) return;

    final uid =
        FcmTokenService.getUserId(userName: userName) ??
        FcmTokenService.vickyUid;
    final isPuja = uid == FcmTokenService.pujaUid;
    final userField = isPuja ? 'loveCountPuja' : 'loveCountVicky';

    try {
      final firestore = FirebaseFirestore.instance;
      final payload = {
        'loveCount': FieldValue.increment(increment),
        userField: FieldValue.increment(increment),
        'lastUpdatedBy': uid,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      };

      // 1. Update shared/stats
      await firestore
          .collection(collectionName)
          .doc(docName)
          .set(payload, SetOptions(merge: true));

      // 2. Also keep couples/puvi_couple organized and synchronized
      await firestore
          .collection(coupleCollectionName)
          .doc(coupleDocName)
          .set(payload, SetOptions(merge: true));

      debugPrint(
        '[LoveStatsService] ✓ Incremented love count by $increment in Firestore for $userName ($uid)',
      );

      // 3. Record in `pings` collection for history & real-time FCM notification trigger
      await firestore.collection('pings').add({
        'senderId': uid,
        'senderName': userName,
        'message': increment > 1
            ? '✨ Sent a Mega Love Shower (+$increment)!'
            : 'Sent a sweet love ping! 💕',
        'count': increment,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(
        '[LoveStatsService] Notice: Error incrementing love count: $e',
      );
    }
  }

  /// Resets or sets the in-memory test count (useful for widget tests).
  @visibleForTesting
  static void setMockLoveCount(int count) {
    _inMemoryLoveCount = count;
  }

  /// Sets mock anniversary date for tests.
  @visibleForTesting
  static void setMockTogetherSince(DateTime date) {
    _togetherSince = date;
  }
}
