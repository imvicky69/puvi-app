import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Information about a GitHub release for Puvi.
class AppReleaseInfo {
  final String version;
  final int? buildNumber;
  final String tagName;
  final String releaseName;
  final String releaseNotes;
  final DateTime? publishedAt;
  final String downloadUrl;
  final String apkName;
  final int fileSize;
  final String architecture;

  const AppReleaseInfo({
    required this.version,
    this.buildNumber,
    required this.tagName,
    required this.releaseName,
    required this.releaseNotes,
    this.publishedAt,
    required this.downloadUrl,
    required this.apkName,
    required this.fileSize,
    required this.architecture,
  });

  String get formattedFileSize {
    if (fileSize <= 0) return '';
    final mb = fileSize / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// Service that checks for newer GitHub releases of Puvi, auto-detects CPU architecture,
/// downloads APKs with real-time progress, and launches the Android Package Installer.
abstract final class AppUpdateService {
  static const String repoOwner = 'imvicky69';
  static const String repoName = 'puvi-app';
  static const String gitHubApiUrl =
      'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';

  static final ValueNotifier<AppReleaseInfo?> latestUpdateNotifier =
      ValueNotifier<AppReleaseInfo?>(null);

  static PackageInfo? _cachedPackageInfo;

  static bool get _isTesting {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return true;
    }
  }

  /// Retrieves current running app package info (version & build number).
  static Future<PackageInfo> getPackageInfo() async {
    if (_cachedPackageInfo != null) return _cachedPackageInfo!;
    if (_isTesting) {
      _cachedPackageInfo = PackageInfo(
        appName: 'Puvi',
        packageName: 'in.xweet.puvi',
        version: '1.0.0',
        buildNumber: '1',
      );
      return _cachedPackageInfo!;
    }
    try {
      _cachedPackageInfo = await PackageInfo.fromPlatform();
      return _cachedPackageInfo!;
    } catch (_) {
      return PackageInfo(
        appName: 'Puvi',
        packageName: 'in.xweet.puvi',
        version: '1.0.0',
        buildNumber: '1',
      );
    }
  }

  /// Checks if a newer release is published on GitHub.
  /// Returns [AppReleaseInfo] if an update is available, or null if currently up to date.
  static Future<AppReleaseInfo?> checkForUpdate() async {
    if (_isTesting) return null;

    try {
      final currentPkg = await getPackageInfo();
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.getUrl(Uri.parse(gitHubApiUrl));
      request.headers.set('User-Agent', 'Puvi-App-Update-Checker');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close();
      if (response.statusCode != 200) {
        debugPrint(
          '[AppUpdateService] GitHub releases query returned ${response.statusCode}',
        );
        return null;
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> data = jsonDecode(responseBody);

      final tagName = data['tag_name']?.toString() ?? '';
      final releaseName = data['name']?.toString() ?? tagName;
      final releaseNotes =
          data['body']?.toString() ?? 'Bug fixes & romantic improvements 💕';
      final publishedAtStr = data['published_at']?.toString();
      final publishedAt = publishedAtStr != null
          ? DateTime.tryParse(publishedAtStr)
          : null;

      final parsedVersion = _extractVersion(tagName);
      final parsedBuildNumber = _extractBuildNumber(tagName, releaseName);

      // Compare semantic version
      final isNewer = isVersionNewer(
        newVersion: parsedVersion,
        newBuild: parsedBuildNumber,
        currentVersion: currentPkg.version,
        currentBuild: int.tryParse(currentPkg.buildNumber) ?? 0,
      );

      if (!isNewer) {
        latestUpdateNotifier.value = null;
        return null;
      }

      // Resolve best matching APK asset based on device architecture
      final assets = (data['assets'] as List<dynamic>?) ?? [];
      final resolvedAsset = await _resolveBestApkAsset(assets);

      if (resolvedAsset == null) {
        debugPrint(
          '[AppUpdateService] Newer release $tagName found, but no matching APK asset is available in release.',
        );
        return null;
      }

      final updateInfo = AppReleaseInfo(
        version: parsedVersion,
        buildNumber: parsedBuildNumber,
        tagName: tagName,
        releaseName: releaseName,
        releaseNotes: releaseNotes,
        publishedAt: publishedAt,
        downloadUrl: resolvedAsset.url,
        apkName: resolvedAsset.name,
        fileSize: resolvedAsset.size,
        architecture: resolvedAsset.architecture,
      );

      latestUpdateNotifier.value = updateInfo;
      return updateInfo;
    } catch (e) {
      debugPrint('[AppUpdateService] Notice checking for update: $e');
      return null;
    }
  }

  /// Downloads the specified APK to local cache with live progress callback.
  static Future<File?> downloadApk(
    AppReleaseInfo release, {
    required void Function(double progress, int received, int total) onProgress,
  }) async {
    if (_isTesting) return null;

    try {
      final tempDir = await getTemporaryDirectory();
      final targetFile = File('${tempDir.path}/${release.apkName}');

      if (await targetFile.exists()) {
        try {
          await targetFile.delete();
        } catch (_) {}
      }

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(release.downloadUrl));
      request.headers.set('User-Agent', 'Puvi-App-Downloader');
      final response = await request.close();

      // Handle GitHub releases redirection (302) to AWS S3
      HttpClientResponse finalResponse = response;
      if (response.statusCode == 302 || response.statusCode == 301) {
        final redirectLocation = response.headers.value('location');
        if (redirectLocation != null) {
          final redirectRequest = await client.getUrl(
            Uri.parse(redirectLocation),
          );
          finalResponse = await redirectRequest.close();
        }
      }

      if (finalResponse.statusCode != 200) {
        debugPrint(
          '[AppUpdateService] Download failed with status ${finalResponse.statusCode}',
        );
        return null;
      }

      final totalBytes = finalResponse.contentLength > 0
          ? finalResponse.contentLength
          : release.fileSize;
      int receivedBytes = 0;

      final sink = targetFile.openWrite();

      await for (final chunk in finalResponse) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          final progress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
          onProgress(progress, receivedBytes, totalBytes);
        }
      }

      await sink.flush();
      await sink.close();

      debugPrint(
        '[AppUpdateService] ✓ APK downloaded successfully: ${targetFile.path} (${targetFile.lengthSync()} bytes)',
      );
      return targetFile;
    } catch (e) {
      debugPrint('[AppUpdateService] Error downloading APK: $e');
      return null;
    }
  }

  /// Launches Android's native package installer for the downloaded APK.
  static Future<bool> installApk(String filePath) async {
    if (_isTesting) return true;

    try {
      final result = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );
      debugPrint(
        '[AppUpdateService] Package installer open result: ${result.type} - ${result.message}',
      );
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('[AppUpdateService] Error triggering package installer: $e');
      return false;
    }
  }

  /// Determines whether [newVersion] / [newBuild] is strictly greater than [currentVersion] / [currentBuild].
  static bool isVersionNewer({
    required String newVersion,
    int? newBuild,
    required String currentVersion,
    int? currentBuild,
  }) {
    final v1Parts = _splitVersion(newVersion);
    final v2Parts = _splitVersion(currentVersion);

    for (int i = 0; i < 3; i++) {
      final p1 = v1Parts[i];
      final p2 = v2Parts[i];
      if (p1 > p2) return true;
      if (p1 < p2) return false;
    }

    // If versions are equal, compare build numbers if present
    if (newBuild != null && currentBuild != null && newBuild > currentBuild) {
      return true;
    }

    return false;
  }

  static List<int> _splitVersion(String version) {
    final clean = version.replaceAll(RegExp(r'[^0-9.]'), '');
    final parts = clean.split('.');
    return [
      parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 0) : 0,
      parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
      parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0,
    ];
  }

  static String _extractVersion(String tagName) {
    final clean = tagName.trim().replaceAll(RegExp(r'^[vV]'), '');
    final match = RegExp(r'(\d+\.\d+\.\d+)').firstMatch(clean);
    return match != null ? match.group(1)! : clean;
  }

  static int? _extractBuildNumber(String tagName, String releaseName) {
    final match = RegExp(r'\+(\d+)').firstMatch('$tagName $releaseName');
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    final buildMatch = RegExp(
      r'build[-_\s]?(\d+)',
      caseSensitive: false,
    ).firstMatch('$tagName $releaseName');
    if (buildMatch != null) {
      return int.tryParse(buildMatch.group(1)!);
    }
    return null;
  }

  /// Resolves the optimal APK asset based on device ABI.
  static Future<_ResolvedAsset?> _resolveBestApkAsset(
    List<dynamic> assets,
  ) async {
    if (assets.isEmpty) return null;

    String primaryAbi = 'arm64-v8a';

    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final supportedAbis = androidInfo.supportedAbis;
        if (supportedAbis.isNotEmpty) {
          primaryAbi = supportedAbis.first;
        }
      }
    } catch (_) {}

    debugPrint(
      '[AppUpdateService] Device primary CPU architecture detected: $primaryAbi',
    );

    // 1. Look for matching split ABI (e.g. arm64-v8a)
    for (final a in assets) {
      final name = (a['name']?.toString() ?? '').toLowerCase();
      final url = a['browser_download_url']?.toString() ?? '';
      final size = (a['size'] is num) ? (a['size'] as num).toInt() : 0;

      if (name.endsWith('.apk') && name.contains(primaryAbi.toLowerCase())) {
        return _ResolvedAsset(
          name: a['name']?.toString() ?? name,
          url: url,
          size: size,
          architecture: primaryAbi,
        );
      }
    }

    // 2. Look for universal APK
    for (final a in assets) {
      final name = (a['name']?.toString() ?? '').toLowerCase();
      final url = a['browser_download_url']?.toString() ?? '';
      final size = (a['size'] is num) ? (a['size'] as num).toInt() : 0;

      if (name.endsWith('.apk') &&
          (name.contains('universal') || name.contains('app-release'))) {
        return _ResolvedAsset(
          name: a['name']?.toString() ?? name,
          url: url,
          size: size,
          architecture: 'Universal',
        );
      }
    }

    // 3. Fallback: Take first available APK
    for (final a in assets) {
      final name = (a['name']?.toString() ?? '').toLowerCase();
      final url = a['browser_download_url']?.toString() ?? '';
      final size = (a['size'] is num) ? (a['size'] as num).toInt() : 0;

      if (name.endsWith('.apk') && url.isNotEmpty) {
        return _ResolvedAsset(
          name: a['name']?.toString() ?? name,
          url: url,
          size: size,
          architecture: 'Standard',
        );
      }
    }

    return null;
  }
}

class _ResolvedAsset {
  final String name;
  final String url;
  final int size;
  final String architecture;

  const _ResolvedAsset({
    required this.name,
    required this.url,
    required this.size,
    required this.architecture,
  });
}
