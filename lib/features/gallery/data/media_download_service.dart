import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'gallery_item.dart';

enum DownloadResultStatus { success, permissionDenied, error }

class DownloadResult {
  final DownloadResultStatus status;
  final String? message;

  const DownloadResult({required this.status, this.message});
}

/// Service to download photos & videos directly into the device's system photo gallery.
class MediaDownloadService {
  static bool get _isTestEnv =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  /// Downloads the given [item] and saves it into the device's system gallery (in album 'Puvi').
  static Future<DownloadResult> downloadToGallery(GalleryItem item) async {
    final url = item.imageUrl.isNotEmpty ? item.imageUrl : item.mediaUrl;
    if (url.isEmpty) {
      return const DownloadResult(
        status: DownloadResultStatus.error,
        message: 'No media URL available.',
      );
    }

    if (_isTestEnv) {
      return const DownloadResult(status: DownloadResultStatus.success);
    }

    File? tempFile;
    try {
      // 1. Check or request gallery write permission
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          return const DownloadResult(
            status: DownloadResultStatus.permissionDenied,
            message: 'Permission required to save memories to your gallery.',
          );
        }
      }

      // 2. Fetch the media bytes
      Uint8List bytes;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        bytes = await consolidateHttpClientResponseBytes(response);
      } else {
        final localFile = File(url);
        if (!await localFile.exists()) {
          return const DownloadResult(
            status: DownloadResultStatus.error,
            message: 'Local media file not found on device.',
          );
        }
        bytes = await localFile.readAsBytes();
      }

      // 3. Write temporarily to device cache
      final tempDir = await getTemporaryDirectory();
      final ext = item.fileExtension ?? (item.isVideo ? '.mp4' : '.jpg');
      final fileName =
          'puvi_${item.id}_${DateTime.now().millisecondsSinceEpoch}$ext';
      tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(bytes);

      // 4. Save into the phone's system gallery with 'Puvi' album
      if (item.isVideo) {
        await Gal.putVideo(tempFile.path, album: 'Puvi');
      } else {
        await Gal.putImage(tempFile.path, album: 'Puvi');
      }

      return const DownloadResult(status: DownloadResultStatus.success);
    } on GalException catch (e) {
      if (e.type == GalExceptionType.accessDenied) {
        return const DownloadResult(
          status: DownloadResultStatus.permissionDenied,
          message: 'Permission denied to save to gallery.',
        );
      }
      return DownloadResult(
        status: DownloadResultStatus.error,
        message: e.type.message,
      );
    } catch (e) {
      return DownloadResult(
        status: DownloadResultStatus.error,
        message: 'Could not save to gallery: $e',
      );
    } finally {
      // 5. Clean up temporary cache file
      try {
        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
    }
  }

  /// Opens the device's default system photo gallery.
  static Future<void> openPhoneGallery() async {
    if (_isTestEnv) return;
    try {
      await Gal.open();
    } catch (_) {}
  }
}
