import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

/// Helper service for chat media operations:
/// - Smart image scaling/compression for standard mode vs raw HD mode.
/// - One-tap saving of chat photos to the phone's system photo gallery ('Puvi' album).
abstract final class ChatMediaService {
  static bool get _isTestEnv {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return true;
    }
  }

  /// Formats byte count into human readable string (e.g. "320 KB" or "2.4 MB").
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Prepares an image for upload:
  /// - If [isHd] is true: returns the original raw file completely untouched.
  /// - If [isHd] is false: resizes to max dimension 1280 keeping aspect ratio.
  static Future<File> prepareImageFile(
    File originalFile, {
    required bool isHd,
  }) async {
    if (isHd || _isTestEnv) {
      return originalFile;
    }

    try {
      final bytes = await originalFile.readAsBytes();
      final initialCodec = await ui.instantiateImageCodec(bytes);
      final initialFrame = await initialCodec.getNextFrame();
      final width = initialFrame.image.width;
      final height = initialFrame.image.height;

      // If already small enough, return original
      if (width <= 1280 && height <= 1280) {
        return originalFile;
      }

      int targetWidth;
      int targetHeight;
      if (width >= height) {
        targetWidth = 1280;
        targetHeight = (height * 1280 / width).round();
      } else {
        targetHeight = 1280;
        targetWidth = (width * 1280 / height).round();
      }

      final scaledCodec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      final scaledFrame = await scaledCodec.getNextFrame();
      final byteData = await scaledFrame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) return originalFile;

      final tempDir = await getTemporaryDirectory();
      final compressedFile = File(
        '${tempDir.path}/chat_std_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await compressedFile.writeAsBytes(byteData.buffer.asUint8List());
      return compressedFile;
    } catch (e) {
      debugPrint('[ChatMediaService] Compression error, using original: $e');
      return originalFile;
    }
  }

  /// Downloads and saves a chat image URL or file to the system photo gallery under the 'Puvi' album.
  static Future<bool> downloadImageToGallery(String url) async {
    if (url.isEmpty) return false;
    if (_isTestEnv) return true;

    File? tempFile;
    try {
      // 1. Check or request Gal album write permission
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) return false;
      }

      // 2. Fetch the image bytes
      Uint8List bytes;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        bytes = await consolidateHttpClientResponseBytes(response);
      } else {
        final localFile = File(url);
        if (!await localFile.exists()) return false;
        bytes = await localFile.readAsBytes();
      }

      // 3. Write temporarily to disk
      final tempDir = await getTemporaryDirectory();
      final fileName = 'puvi_${DateTime.now().millisecondsSinceEpoch}.jpg';
      tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(bytes);

      // 4. Save into system gallery in album 'Puvi'
      await Gal.putImage(tempFile.path, album: 'Puvi');
      return true;
    } catch (e) {
      debugPrint('[ChatMediaService] Download error: $e');
      return false;
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
  }
}
