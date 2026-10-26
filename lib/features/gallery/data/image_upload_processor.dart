import 'dart:io';
import 'dart:ui' as ui;
import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'gallery_item.dart';

/// In-memory representation of an image being prepared for upload.
class UploadDraft {
  final String id;
  final String originalName;
  final String originalPath;
  Uint8List processedBytes;
  String fileExtension; // '.jpg' or '.png'
  DateTime date;
  String note;
  double aspectRatio;
  final bool wasHeic;

  UploadDraft({
    required this.id,
    required this.originalName,
    required this.originalPath,
    required this.processedBytes,
    required this.fileExtension,
    required this.date,
    this.note = '',
    required this.aspectRatio,
    this.wasHeic = false,
  });

  /// Formatted date preview for UI chips (e.g. "May 25, 2026")
  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final m = months[date.month - 1];
    return '$m ${date.day}, ${date.year}';
  }
}

/// Service to process, auto-detect dates, convert HEIC to PNG/JPG, and persist uploaded memories.
class ImageUploadProcessor {
  /// Extracts date from EXIF tags across multiple formats and key variations.
  static DateTime? _extractDateFromExif(Map<String, IfdTag> exifData) {
    // 1. Primary standard EXIF tags
    const candidateKeys = [
      'EXIF DateTimeOriginal',
      'Image DateTime',
      'EXIF DateTimeDigitized',
      'DateTimeOriginal',
      'DateTimeDigitized',
      'DateTime',
      'GPS GPSDate',
    ];

    for (final key in candidateKeys) {
      if (exifData.containsKey(key)) {
        final parsed = _parseDateTimeString(exifData[key]?.printable);
        if (parsed != null) return parsed;
      }
    }

    // 2. Case-insensitive search across any tag mentioning date or time
    for (final entry in exifData.entries) {
      final lowerKey = entry.key.toLowerCase();
      if (lowerKey.contains('datetime') || lowerKey.contains('date')) {
        final parsed = _parseDateTimeString(entry.value.printable);
        if (parsed != null) return parsed;
      }
    }

    return null;
  }

  /// Parses date & time from raw strings like "2024:05:25 14:30:15", "2024-05-25", etc.
  static DateTime? _parseDateTimeString(String? raw) {
    if (raw == null) return null;
    final cleaned = raw
        .replaceAll('\x00', '')
        .replaceAll("'", '')
        .replaceAll('"', '')
        .trim();
    if (cleaned.isEmpty) return null;

    // Pattern: YYYY:MM:DD or YYYY-MM-DD or YYYY/MM/DD
    final dateMatch = RegExp(
      r'(\d{4})[:\-\/](\d{1,2})[:\-\/](\d{1,2})',
    ).firstMatch(cleaned);
    if (dateMatch != null) {
      final year = int.tryParse(dateMatch.group(1)!);
      final month = int.tryParse(dateMatch.group(2)!);
      final day = int.tryParse(dateMatch.group(3)!);

      if (year != null &&
          month != null &&
          day != null &&
          year >= 1990 &&
          year <= 2040 &&
          month >= 1 &&
          month <= 12 &&
          day >= 1 &&
          day <= 31) {
        // Try extracting time HH:MM:SS
        int hour = 12, minute = 0, second = 0;
        final timeMatch = RegExp(
          r'(\d{1,2})[:\.](\d{1,2})(?:[:\.](\d{1,2}))?',
        ).firstMatch(cleaned.substring(dateMatch.end));
        if (timeMatch != null) {
          hour = int.tryParse(timeMatch.group(1)!) ?? 12;
          minute = int.tryParse(timeMatch.group(2)!) ?? 0;
          second = int.tryParse(timeMatch.group(3) ?? '0') ?? 0;
        }

        return DateTime(
          year,
          month,
          day,
          hour.clamp(0, 23),
          minute.clamp(0, 59),
          second.clamp(0, 59),
        );
      }
    }

    return DateTime.tryParse(cleaned);
  }

  /// Extracts capture date from photo filenames (e.g. IMG_20240525_143022, Screenshot_2024-05-25, WhatsApp Image 2024-05-25, 1716645600000).
  static DateTime? _extractDateFromFilename(String fileName, String filePath) {
    final targets = [fileName, filePath.split('/').last.split('\\').last];

    for (final text in targets) {
      // Format 1: YYYYMMDD or YYYY-MM-DD or YYYY_MM_DD (e.g. 20240525, 2024-05-25, 2024_05_25)
      final ymdMatch = RegExp(
        r'(?:^|[^0-9])(20[12]\d)[-_.]?(0[1-9]|1[0-2])[-_.]?(0[1-9]|[12]\d|3[01])(?:[^0-9]|$)',
      ).firstMatch(text);
      if (ymdMatch != null) {
        final year = int.tryParse(ymdMatch.group(1)!);
        final month = int.tryParse(ymdMatch.group(2)!);
        final day = int.tryParse(ymdMatch.group(3)!);

        if (year != null && month != null && day != null) {
          // Check if time HHMMSS or HH-MM-SS follows
          int hour = 12, minute = 0, second = 0;
          final afterDate = text.substring(ymdMatch.end);
          final timeMatch = RegExp(
            r'[-_ ](\d{2})[-_.]?(\d{2})[-_.]?(\d{2})',
          ).firstMatch(afterDate);
          if (timeMatch != null) {
            hour = int.tryParse(timeMatch.group(1)!) ?? 12;
            minute = int.tryParse(timeMatch.group(2)!) ?? 0;
            second = int.tryParse(timeMatch.group(3)!) ?? 0;
          }

          return DateTime(
            year,
            month,
            day,
            hour.clamp(0, 23),
            minute.clamp(0, 59),
            second.clamp(0, 59),
          );
        }
      }

      // Format 2: DD-MM-YYYY or DD_MM_YYYY (e.g. 25-05-2024)
      final dmyMatch = RegExp(
        r'(?:^|[^0-9])(0[1-9]|[12]\d|3[01])[-_.](0[1-9]|1[0-2])[-_.](20[12]\d)(?:[^0-9]|$)',
      ).firstMatch(text);
      if (dmyMatch != null) {
        final day = int.tryParse(dmyMatch.group(1)!);
        final month = int.tryParse(dmyMatch.group(2)!);
        final year = int.tryParse(dmyMatch.group(3)!);
        if (year != null && month != null && day != null) {
          return DateTime(year, month, day, 12, 0, 0);
        }
      }

      // Format 3: 13-digit Unix timestamp in ms (e.g. 1716645600000 -> 2024)
      final msMatch = RegExp(
        r'(?:^|[^0-9])(1[5-8]\d{11})(?:[^0-9]|$)',
      ).firstMatch(text);
      if (msMatch != null) {
        final ms = int.tryParse(msMatch.group(1)!);
        if (ms != null) {
          final dt = DateTime.fromMillisecondsSinceEpoch(ms);
          if (dt.year >= 2017 && dt.year <= 2035) {
            return dt;
          }
        }
      }

      // Format 4: 10-digit Unix timestamp in seconds (e.g. 1716645600)
      final secMatch = RegExp(
        r'(?:^|[^0-9])(1[5-8]\d{8})(?:[^0-9]|$)',
      ).firstMatch(text);
      if (secMatch != null) {
        final sec = int.tryParse(secMatch.group(1)!);
        if (sec != null) {
          final dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
          if (dt.year >= 2017 && dt.year <= 2035) {
            return dt;
          }
        }
      }
    }

    return null;
  }

  /// Processes an [XFile] picked from gallery or camera:
  /// - Auto-detects capture date via multi-tier EXIF, filename patterns, and non-cache file stats.
  /// - If iPhone HEIC format, decodes and converts to universal PNG format.
  /// - Accurately calculates natural aspect ratio so it displays unclipped.
  static Future<UploadDraft> processPickedFile(XFile file) async {
    final bytes = await file.readAsBytes();
    final fileName = file.name;
    final lowerName = fileName.toLowerCase();
    final isHeic = lowerName.endsWith('.heic') || lowerName.endsWith('.heif');

    // 1. Multi-tier date detection
    DateTime detectedDate = DateTime.now();

    // Tier A: EXIF metadata
    try {
      final exifData = await readExifFromBytes(bytes);
      final exifDate = _extractDateFromExif(exifData);
      if (exifDate != null) {
        detectedDate = exifDate;
      } else {
        // Tier B: Filename date patterns
        final nameDate = _extractDateFromFilename(fileName, file.path);
        if (nameDate != null) {
          detectedDate = nameDate;
        } else {
          // Tier C: File system lastModified (only if older than 5 min to avoid picker cache timestamp)
          final fileStat = await File(file.path).lastModified();
          if (fileStat.isBefore(
            DateTime.now().subtract(const Duration(minutes: 5)),
          )) {
            detectedDate = fileStat;
          }
        }
      }
    } catch (_) {
      // Fallback to filename patterns if EXIF decoding fails
      final nameDate = _extractDateFromFilename(fileName, file.path);
      if (nameDate != null) {
        detectedDate = nameDate;
      } else {
        try {
          final fileStat = await File(file.path).lastModified();
          if (fileStat.isBefore(
            DateTime.now().subtract(const Duration(minutes: 5)),
          )) {
            detectedDate = fileStat;
          }
        } catch (_) {}
      }
    }

    // 2. Decode image for dimensions & HEIC conversion if needed
    Uint8List finalBytes = bytes;
    String finalExt = lowerName.endsWith('.png') ? '.png' : '.jpg';
    double computedAspectRatio = 0.75;
    bool wasConverted = false;

    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final width = frame.image.width;
      final height = frame.image.height;

      if (width > 0 && height > 0) {
        computedAspectRatio = (width / height).clamp(0.48, 2.0);
      }

      // If HEIC from iPhone, re-encode to high-quality universal PNG
      if (isHeic) {
        final byteData = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (byteData != null) {
          finalBytes = byteData.buffer.asUint8List();
          finalExt = '.png';
          wasConverted = true;
        }
      }
    } catch (_) {
      // If decoding fails (e.g. in headless unit tests), preserve bytes with safe default aspect ratio
      if (isHeic) {
        finalExt = '.jpg';
      }
    }

    return UploadDraft(
      id: 'draft_${DateTime.now().microsecondsSinceEpoch}',
      originalName: fileName,
      originalPath: file.path,
      processedBytes: finalBytes,
      fileExtension: finalExt,
      date: detectedDate,
      aspectRatio: computedAspectRatio,
      wasHeic: wasConverted || isHeic,
    );
  }

  /// Persists the draft to permanent local storage and generates a [GalleryItem].
  static Future<GalleryItem> saveDraftToPermanentStorage(
    UploadDraft draft,
  ) async {
    final appDir = await getApplicationDocumentsDirectory();
    final uploadDir = Directory('${appDir.path}/user_memories');
    if (!await uploadDir.exists()) {
      await uploadDir.create(recursive: true);
    }

    final uniqueId = 'mem_${DateTime.now().microsecondsSinceEpoch}';
    final targetFile = File(
      '${uploadDir.path}/$uniqueId${draft.fileExtension}',
    );
    await targetFile.writeAsBytes(draft.processedBytes);

    return GalleryItem(
      id: uniqueId,
      imageUrl: targetFile.path,
      mediaUrl: targetFile.path,
      thumbnailUrl: targetFile.path,
      storagePath: 'user_memories/$uniqueId${draft.fileExtension}',
      title: draft.note.trim().isNotEmpty ? draft.note.trim() : 'Our memory',
      type: 'image',
      isVideo: false,
      createdAt: DateTime.now(),
      takenAt: draft.date,
      coupleId: 'puvi_couple',
      aspectRatio: draft.aspectRatio,
      fileExtension: draft.fileExtension,
    );
  }
}
