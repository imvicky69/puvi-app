import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/couple_encryption_service.dart';

/// Supported types of chat messages and dramatic couple emotions.
abstract final class ChatMessageType {
  static const String text = 'text';
  static const String kiss = 'kiss';
  static const String hug = 'hug';
  static const String knife = 'knife';
  static const String flower = 'flower';
  static const String audio = 'audio';
}

/// Representation of a single encrypted couple chat message, dramatic emotion,
/// or voice note memo.
class ChatMessage {
  final String id;
  final String coupleId;
  final String senderId;
  final String receiverId;
  final String type;
  final String text;
  final String rawText;
  final String? mediaUrl;
  final int durationSeconds;
  final DateTime createdAt;
  final bool isSeen;
  final bool isEncrypted;
  final bool isEdited;
  final DateTime? editedAt;

  const ChatMessage({
    required this.id,
    this.coupleId = CoupleEncryptionService.coupleId,
    required this.senderId,
    required this.receiverId,
    this.type = ChatMessageType.text,
    required this.text,
    required this.rawText,
    this.mediaUrl,
    this.durationSeconds = 0,
    required this.createdAt,
    this.isSeen = false,
    this.isEncrypted = true,
    this.isEdited = false,
    this.editedAt,
  });

  bool get isKiss => type == ChatMessageType.kiss;
  bool get isHug => type == ChatMessageType.hug;
  bool get isKnife => type == ChatMessageType.knife;
  bool get isFlower => type == ChatMessageType.flower;
  bool get isAudio => type == ChatMessageType.audio;
  bool get isEmotion => isKiss || isHug || isKnife || isFlower;

  /// Returns the corresponding expressive emoji for this message type.
  String get emotionEmoji {
    switch (type) {
      case ChatMessageType.kiss:
        return '💋';
      case ChatMessageType.hug:
        return '🤗';
      case ChatMessageType.knife:
        return '🔪';
      case ChatMessageType.flower:
        return '🌸';
      case ChatMessageType.audio:
        return '🎙️';
      default:
        return '✉️';
    }
  }

  /// Returns romantic display title for action cards.
  String emotionTitle({required bool isMe, required String partnerName}) {
    final subject = isMe ? 'You' : partnerName;
    switch (type) {
      case ChatMessageType.kiss:
        return isMe ? 'You sent a kiss 💋' : '$subject sent you a kiss 💋';
      case ChatMessageType.hug:
        return isMe ? 'You sent a hug 🤗' : '$subject wrapped you in a hug 🤗';
      case ChatMessageType.knife:
        return isMe ? 'You are angry! 🔪' : '$subject is angry with you! 🔪';
      case ChatMessageType.flower:
        return isMe
            ? 'You sent fresh flowers 🌸'
            : '$subject showered you with flowers 🌸';
      case ChatMessageType.audio:
        return isMe
            ? 'You sent a voice memo 🎙️'
            : '$subject sent you a voice memo 🎙️';
      default:
        return '$subject sent a note';
    }
  }

  /// Deserializes a Firestore document snapshot, transparently decrypting ciphertext.
  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ChatMessage.fromMap(doc.id, data);
  }

  /// Deserializes a raw map, transparently decrypting ciphertext.
  factory ChatMessage.fromMap(String id, Map<String, dynamic> data) {
    final senderId = data['senderId']?.toString() ?? '';
    final rawReceiverId = data['receiverId']?.toString();
    final receiverId = (rawReceiverId != null && rawReceiverId.isNotEmpty)
        ? rawReceiverId
        : (senderId == CoupleEncryptionService.pujaUid
              ? CoupleEncryptionService.vickyUid
              : CoupleEncryptionService.pujaUid);

    // Parse date from either Firestore Timestamp or ISO 8601 string
    DateTime parsedDate = DateTime.now();
    final rawTimestamp = data['timestamp'];
    final rawCreatedAt = data['createdAt'];

    if (rawTimestamp is Timestamp) {
      parsedDate = rawTimestamp.toDate();
    } else if (rawCreatedAt is String) {
      parsedDate = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else if (rawTimestamp is String) {
      parsedDate = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    }

    final rawEditedAt = data['editedAt'];
    DateTime? parsedEditedAt;
    if (rawEditedAt is Timestamp) {
      parsedEditedAt = rawEditedAt.toDate();
    } else if (rawEditedAt is String) {
      parsedEditedAt = DateTime.tryParse(rawEditedAt);
    }

    final rawText = data['text']?.toString() ?? '';
    final isEncrypted = data['isEncrypted'] == true;
    final decryptedText =
        isEncrypted || rawText.startsWith(CoupleEncryptionService.prefix)
        ? CoupleEncryptionService.decrypt(rawText)
        : rawText;

    final mediaUrl = data['mediaUrl']?.toString();
    final durationSeconds =
        (data['durationSeconds'] as num?)?.toInt() ??
        (data['duration'] as num?)?.toInt() ??
        0;

    return ChatMessage(
      id: id,
      coupleId:
          data['coupleId']?.toString() ?? CoupleEncryptionService.coupleId,
      senderId: senderId,
      receiverId: receiverId,
      type: data['type']?.toString() ?? ChatMessageType.text,
      text: decryptedText,
      rawText: rawText,
      mediaUrl: mediaUrl,
      durationSeconds: durationSeconds,
      createdAt: parsedDate,
      isSeen: data['isSeen'] == true,
      isEncrypted: isEncrypted,
      isEdited: data['isEdited'] == true,
      editedAt: parsedEditedAt,
    );
  }

  /// Serializes into a Firestore payload with End-to-End Encryption applied to [text].
  Map<String, dynamic> toFirestore() {
    final encryptedText = text.isNotEmpty
        ? CoupleEncryptionService.encrypt(text)
        : '';
    final map = <String, dynamic>{
      'coupleId': coupleId,
      'senderId': senderId,
      'receiverId': receiverId,
      'type': type,
      'text': encryptedText,
      'isEncrypted': text.isNotEmpty,
      'isSeen': isSeen,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (mediaUrl != null && mediaUrl!.isNotEmpty) {
      map['mediaUrl'] = mediaUrl;
      map['durationSeconds'] = durationSeconds;
    }

    if (isEdited) {
      map['isEdited'] = true;
      if (editedAt != null) {
        map['editedAt'] = editedAt!.toUtc().toIso8601String();
      }
    }

    return map;
  }

  ChatMessage copyWith({
    String? id,
    String? coupleId,
    String? senderId,
    String? receiverId,
    String? type,
    String? text,
    String? rawText,
    String? mediaUrl,
    int? durationSeconds,
    DateTime? createdAt,
    bool? isSeen,
    bool? isEncrypted,
    bool? isEdited,
    DateTime? editedAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      text: text ?? this.text,
      rawText: rawText ?? this.rawText,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
      isSeen: isSeen ?? this.isSeen,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
    );
  }
}
