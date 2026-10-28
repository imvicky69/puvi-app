import 'package:flutter_test/flutter_test.dart';
import 'package:puvi/core/services/couple_encryption_service.dart';
import 'package:puvi/features/chat/data/chat_message.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CoupleEncryptionService Tests', () {
    setUpAll(() async {
      await CoupleEncryptionService.initialize(
        overrideSecret: 'test_puvi_secret_2026',
      );
    });

    test('Encrypts and decrypts plain text message correctly', () {
      const original = 'Hello Puja! My heart belongs to you 💕';
      final encrypted = CoupleEncryptionService.encrypt(original);

      expect(encrypted.startsWith(CoupleEncryptionService.prefix), isTrue);
      expect(encrypted, isNot(equals(original)));

      final decrypted = CoupleEncryptionService.decrypt(encrypted);
      expect(decrypted, equals(original));
    });

    test('Gracefully handles empty strings and already-encrypted strings', () {
      expect(CoupleEncryptionService.encrypt(''), equals(''));
      expect(CoupleEncryptionService.decrypt(''), equals(''));

      const alreadyEncrypted = 'enc:v1:fake_iv:fake_cipher';
      expect(
        CoupleEncryptionService.encrypt(alreadyEncrypted),
        equals(alreadyEncrypted),
      );
    });

    test(
      'Gracefully falls back when decrypting non-encrypted legacy string',
      () {
        const plain = 'Legacy plain message';
        expect(CoupleEncryptionService.decrypt(plain), equals(plain));
      },
    );
  });

  group('ChatMessage Model Tests', () {
    test('Correctly identifies emotion types and titles', () {
      final kiss = ChatMessage(
        id: '1',
        senderId: CoupleEncryptionService.pujaUid,
        receiverId: CoupleEncryptionService.vickyUid,
        type: ChatMessageType.kiss,
        text: '',
        rawText: '',
        createdAt: DateTime(2026, 7, 4),
      );

      expect(kiss.isKiss, isTrue);
      expect(kiss.isEmotion, isTrue);
      expect(kiss.emotionEmoji, equals('💋'));
      expect(
        kiss.emotionTitle(isMe: true, partnerName: 'Vicky'),
        contains('You sent a kiss'),
      );
      expect(
        kiss.emotionTitle(isMe: false, partnerName: 'Puja'),
        contains('Puja sent you a kiss'),
      );

      final knife = ChatMessage(
        id: '2',
        senderId: CoupleEncryptionService.pujaUid,
        receiverId: CoupleEncryptionService.vickyUid,
        type: ChatMessageType.knife,
        text: '',
        rawText: '',
        createdAt: DateTime(2026, 7, 4),
      );
      expect(knife.isKnife, isTrue);
      expect(knife.isEmotion, isTrue);
      expect(knife.emotionEmoji, equals('🔪'));

      final flower = ChatMessage(
        id: '3',
        senderId: CoupleEncryptionService.vickyUid,
        receiverId: CoupleEncryptionService.pujaUid,
        type: ChatMessageType.flower,
        text: '',
        rawText: '',
        createdAt: DateTime(2026, 7, 4),
      );
      expect(flower.isFlower, isTrue);
      expect(flower.isEmotion, isTrue);
      expect(flower.emotionEmoji, equals('🌸'));
    });

    test('Deserializes from Firestore Map with transparent decryption', () {
      const plainNote = 'Meet me at Lanka VT tonight! 💕';
      final encryptedNote = CoupleEncryptionService.encrypt(plainNote);

      final rawMap = {
        'coupleId': 'puvi_couple',
        'senderId': CoupleEncryptionService.vickyUid,
        'receiverId': CoupleEncryptionService.pujaUid,
        'type': 'text',
        'text': encryptedNote,
        'isEncrypted': true,
        'isSeen': true,
        'createdAt': '2026-07-04T18:52:31.236Z',
      };

      final msg = ChatMessage.fromMap('msg_101', rawMap);
      expect(msg.id, equals('msg_101'));
      expect(msg.text, equals(plainNote));
      expect(msg.rawText, equals(encryptedNote));
      expect(msg.isSeen, isTrue);
      expect(msg.createdAt.year, equals(2026));
    });

    test('Correctly handles audio voice note model and serialization', () {
      final audio = ChatMessage(
        id: 'voice_1',
        senderId: CoupleEncryptionService.vickyUid,
        receiverId: CoupleEncryptionService.pujaUid,
        type: ChatMessageType.audio,
        text: '',
        rawText: '',
        mediaUrl: 'https://firebasestorage.local/voice_notes/memo.m4a',
        durationSeconds: 12,
        createdAt: DateTime(2026, 7, 4),
      );

      expect(audio.isAudio, isTrue);
      expect(audio.durationSeconds, equals(12));
      expect(audio.mediaUrl, contains('memo.m4a'));
      expect(audio.emotionEmoji, equals('🎙️'));

      final firestoreMap = audio.toFirestore();
      expect(firestoreMap['mediaUrl'], equals(audio.mediaUrl));
      expect(firestoreMap['durationSeconds'], equals(12));
      expect(firestoreMap['type'], equals(ChatMessageType.audio));

      final roundTrip = ChatMessage.fromMap('voice_1', firestoreMap);
      expect(roundTrip.isAudio, isTrue);
      expect(roundTrip.durationSeconds, equals(12));
      expect(roundTrip.mediaUrl, equals(audio.mediaUrl));
    });

    test('Correctly handles edited message flag and timestamp', () {
      final edited = ChatMessage(
        id: 'msg_2',
        senderId: CoupleEncryptionService.pujaUid,
        receiverId: CoupleEncryptionService.vickyUid,
        type: ChatMessageType.text,
        text: 'Edited text note',
        rawText: 'Edited text note',
        createdAt: DateTime(2026, 7, 4),
        isEdited: true,
        editedAt: DateTime(2026, 7, 4, 12, 30),
      );

      expect(edited.isEdited, isTrue);
      expect(edited.editedAt, isNotNull);

      final map = edited.toFirestore();
      expect(map['isEdited'], isTrue);
      expect(map['editedAt'], isNotNull);

      final roundTrip = ChatMessage.fromMap('msg_2', map);
      expect(roundTrip.isEdited, isTrue);
      expect(roundTrip.editedAt?.toLocal().minute, equals(30));
    });
  });
}
