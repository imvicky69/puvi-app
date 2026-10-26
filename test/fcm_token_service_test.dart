import 'package:flutter_test/flutter_test.dart';
import 'package:puvi/core/services/fcm_token_service.dart';

void main() {
  group('FcmTokenService Tests', () {
    test('Maps Puja user and email to verified UID', () {
      expect(
        FcmTokenService.getUserId(userName: 'Puja'),
        FcmTokenService.pujaUid,
      );
      expect(
        FcmTokenService.getUserId(userName: 'puja', email: 'puja@puvi.com'),
        FcmTokenService.pujaUid,
      );
    });

    test('Maps Vicky user and email to verified UID', () {
      expect(
        FcmTokenService.getUserId(userName: 'Vicky'),
        FcmTokenService.vickyUid,
      );
      expect(
        FcmTokenService.getUserId(userName: 'vicky', email: 'vicky@puvi.com'),
        FcmTokenService.vickyUid,
      );
    });

    test('Returns null for unrecognized user', () {
      expect(
        FcmTokenService.getUserId(
          userName: 'Unknown',
          email: 'unknown@test.com',
        ),
        isNull,
      );
    });

    test(
      'syncUserFcmToken executes safely without throwing in test environment',
      () async {
        // In test runner, it should safely return immediately without exceptions
        await expectLater(
          FcmTokenService.syncUserFcmToken(
            userName: 'Vicky',
            email: 'vicky@puvi.com',
          ),
          completes,
        );
      },
    );
  });
}
