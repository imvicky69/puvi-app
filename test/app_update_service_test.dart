import 'package:flutter_test/flutter_test.dart';
import 'package:puvi/core/services/app_update_service.dart';

void main() {
  group('AppUpdateService Semantic Versioning Tests', () {
    test('isVersionNewer correctly detects higher patch version', () {
      expect(
        AppUpdateService.isVersionNewer(
          newVersion: '1.0.1',
          currentVersion: '1.0.0',
        ),
        isTrue,
      );
    });

    test('isVersionNewer correctly detects higher minor version', () {
      expect(
        AppUpdateService.isVersionNewer(
          newVersion: '1.1.0',
          currentVersion: '1.0.5',
        ),
        isTrue,
      );
    });

    test('isVersionNewer correctly detects higher major version', () {
      expect(
        AppUpdateService.isVersionNewer(
          newVersion: '2.0.0',
          currentVersion: '1.9.9',
        ),
        isTrue,
      );
    });

    test('isVersionNewer returns false for older version', () {
      expect(
        AppUpdateService.isVersionNewer(
          newVersion: '1.0.0',
          currentVersion: '1.0.1',
        ),
        isFalse,
      );
    });

    test('isVersionNewer returns false for identical version and build', () {
      expect(
        AppUpdateService.isVersionNewer(
          newVersion: '1.0.0',
          newBuild: 1,
          currentVersion: '1.0.0',
          currentBuild: 1,
        ),
        isFalse,
      );
    });

    test('isVersionNewer detects higher build number when versions match', () {
      expect(
        AppUpdateService.isVersionNewer(
          newVersion: '1.0.0',
          newBuild: 2,
          currentVersion: '1.0.0',
          currentBuild: 1,
        ),
        isTrue,
      );
    });

    test('Formatted file size formats MB accurately', () {
      const release = AppReleaseInfo(
        version: '1.0.1',
        buildNumber: 2,
        tagName: 'v1.0.1',
        releaseName: 'Puvi 1.0.1',
        releaseNotes: 'Romantic update',
        downloadUrl: 'https://github.com/imvicky69/puvi-app/releases',
        apkName: 'puvi-v1.0.1-arm64-v8a.apk',
        fileSize: 22 * 1024 * 1024,
        architecture: 'arm64-v8a',
      );
      expect(release.formattedFileSize, '22.0 MB');
    });
  });
}
