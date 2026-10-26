import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:puvi/features/gallery/data/image_upload_processor.dart';

void main() {
  group('ImageUploadProcessor Date Detection Tests', () {
    test('Detects date from standard camera filename YYYYMMDD', () async {
      // Create a dummy XFile with filename IMG_20240602_143022.jpg
      final file = XFile.fromData(
        Uint8List.fromList([
          0xFF,
          0xD8,
          0xFF,
          0xE0,
          0x00,
          0x10,
          0x4A,
          0x46,
          0x49,
          0x46,
        ]),
        name: 'IMG_20240602_143022.jpg',
        path: '/storage/emulated/0/DCIM/Camera/IMG_20240602_143022.jpg',
      );

      final draft = await ImageUploadProcessor.processPickedFile(file);
      expect(draft.date.year, equals(2024));
      expect(draft.date.month, equals(6));
      expect(draft.date.day, equals(2));
      expect(draft.formattedDate, equals('Jun 2, 2024'));
    });

    test('Detects date from WhatsApp filename format', () async {
      final file = XFile.fromData(
        Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]),
        name: 'WhatsApp Image 2023-08-15 at 14.30.22.jpeg',
        path:
            '/storage/emulated/0/WhatsApp/WhatsApp Image 2023-08-15 at 14.30.22.jpeg',
      );

      final draft = await ImageUploadProcessor.processPickedFile(file);
      expect(draft.date.year, equals(2023));
      expect(draft.date.month, equals(8));
      expect(draft.date.day, equals(15));
      expect(draft.formattedDate, equals('Aug 15, 2023'));
    });

    test('Detects date from screenshot filename format', () async {
      final file = XFile.fromData(
        Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]),
        name: 'Screenshot_2025-11-20-10-45-12.png',
        path:
            '/storage/emulated/0/Pictures/Screenshots/Screenshot_2025-11-20-10-45-12.png',
      );

      final draft = await ImageUploadProcessor.processPickedFile(file);
      expect(draft.date.year, equals(2025));
      expect(draft.date.month, equals(11));
      expect(draft.date.day, equals(20));
      expect(draft.formattedDate, equals('Nov 20, 2025'));
    });

    test('Detects date from Unix millisecond timestamp filename', () async {
      // 1717286400000 = June 2, 2024 00:00:00 UTC
      final file = XFile.fromData(
        Uint8List.fromList([0xFF, 0xD8, 0xFF]),
        name: '1717286400000.jpg',
        path: '/cache/1717286400000.jpg',
      );

      final draft = await ImageUploadProcessor.processPickedFile(file);
      expect(draft.date.year, equals(2024));
      expect(draft.date.month, equals(6));
    });
  });
}
