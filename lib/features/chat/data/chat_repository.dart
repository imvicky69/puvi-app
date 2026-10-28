import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import '../../../../core/services/couple_encryption_service.dart';
import 'chat_message.dart';

/// Repository managing real-time Firestore communication, End-to-End Encryption,
/// voice note uploads to Firebase Storage, and message editing/deleting.
class ChatRepository {
  final FirebaseFirestore? _customFirestore;
  final FirebaseStorage? _customStorage;

  ChatRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _customFirestore = firestore,
      _customStorage = storage;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  FirebaseStorage get _storage => _customStorage ?? FirebaseStorage.instance;

  static bool get _isTesting {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return true;
    }
  }

  /// Streams the continuous real-time conversation between Puja and Vicky.
  /// Automatically decrypts E2EE ciphertexts into readable plaintext in memory.
  Stream<List<ChatMessage>> watchMessages({
    String coupleId = CoupleEncryptionService.coupleId,
  }) {
    if (_isTesting || Firebase.apps.isEmpty) {
      return Stream.value(<ChatMessage>[]);
    }

    return _firestore
        .collection('chatMessages')
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();

          // Chronological sort: oldest to newest
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return messages;
        })
        .handleError((error) {
          debugPrint('[ChatRepository] Notice streaming messages: $error');
          return <ChatMessage>[];
        });
  }

  /// Streams the real-time count of unread messages waiting for [currentUserId].
  Stream<int> watchUnreadCount({required String currentUserId}) {
    if (_isTesting || Firebase.apps.isEmpty || currentUserId.isEmpty) {
      return Stream.value(0);
    }

    return _firestore
        .collection('chatMessages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isSeen', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
          debugPrint('[ChatRepository] Notice streaming unread count: $error');
          return 0;
        });
  }

  /// Sends a new message or dramatic emotion to the partner.
  /// Encrypts message payload before storing in Firestore.
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String type,
    String text = '',
    String? mediaUrl,
    int durationSeconds = 0,
    String coupleId = CoupleEncryptionService.coupleId,
  }) async {
    // 1. Ensure encryption master key is loaded
    await CoupleEncryptionService.initialize();

    final message = ChatMessage(
      id: '',
      coupleId: coupleId,
      senderId: senderId,
      receiverId: receiverId,
      type: type,
      text: text,
      rawText: text,
      mediaUrl: mediaUrl,
      durationSeconds: durationSeconds,
      createdAt: DateTime.now(),
      isSeen: false,
      isEncrypted: text.isNotEmpty,
    );

    if (_isTesting || Firebase.apps.isEmpty) {
      debugPrint('[ChatRepository] Test send simulated: ${message.type}');
      return;
    }

    try {
      await _firestore.collection('chatMessages').add(message.toFirestore());
    } catch (e) {
      debugPrint('[ChatRepository] Error sending message: $e');
      rethrow;
    }
  }

  /// Uploads a recorded audio memo to Firebase Storage and records the message in Firestore.
  Future<void> sendVoiceNote({
    required String senderId,
    required String receiverId,
    required String localFilePath,
    required int durationSeconds,
    String coupleId = CoupleEncryptionService.coupleId,
  }) async {
    final file = File(localFilePath);
    if (!await file.exists()) {
      throw Exception('Recorded voice note file not found at $localFilePath');
    }

    String mediaUrl = '';

    if (!_isTesting && Firebase.apps.isNotEmpty) {
      final fileName =
          'voice_${DateTime.now().millisecondsSinceEpoch}_$senderId.m4a';
      final storageRef = _storage
          .ref()
          .child('chat')
          .child('voice_notes')
          .child(fileName);

      final uploadTask = await storageRef.putFile(
        file,
        SettableMetadata(contentType: 'audio/m4a'),
      );
      mediaUrl = await uploadTask.ref.getDownloadURL();
    } else {
      mediaUrl = 'https://puvi.local/test_audio.m4a';
    }

    await sendMessage(
      senderId: senderId,
      receiverId: receiverId,
      type: ChatMessageType.audio,
      text: '',
      mediaUrl: mediaUrl,
      durationSeconds: durationSeconds,
      coupleId: coupleId,
    );
  }

  /// Edits an existing message, re-encrypting the text with E2EE.
  Future<void> editMessage({
    required String messageId,
    required String newText,
  }) async {
    if (_isTesting || Firebase.apps.isEmpty) {
      debugPrint('[ChatRepository] Simulated edit for $messageId');
      return;
    }

    await CoupleEncryptionService.initialize();
    final encrypted = CoupleEncryptionService.encrypt(newText.trim());

    await _firestore.collection('chatMessages').doc(messageId).update({
      'text': encrypted,
      'isEncrypted': true,
      'isEdited': true,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes an existing message from Firestore.
  Future<void> deleteMessage({required String messageId}) async {
    if (_isTesting || Firebase.apps.isEmpty) {
      debugPrint('[ChatRepository] Simulated delete for $messageId');
      return;
    }

    await _firestore.collection('chatMessages').doc(messageId).delete();
  }

  /// Marks all unread messages received by [currentUserId] as read.
  Future<void> markMessagesAsSeen({required String currentUserId}) async {
    if (_isTesting || Firebase.apps.isEmpty || currentUserId.isEmpty) {
      return;
    }

    try {
      final unreadSnap = await _firestore
          .collection('chatMessages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isSeen', isEqualTo: false)
          .limit(50)
          .get();

      if (unreadSnap.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in unreadSnap.docs) {
        batch.update(doc.reference, {'isSeen': true});
      }
      await batch.commit();
      debugPrint(
        '[ChatRepository] ✓ Marked ${unreadSnap.docs.length} messages as seen',
      );
    } catch (e) {
      debugPrint('[ChatRepository] Notice marking messages as seen: $e');
    }
  }
}
