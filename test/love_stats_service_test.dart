import 'package:flutter_test/flutter_test.dart';
import 'package:puvi/core/services/love_stats_service.dart';

void main() {
  group('LoveStatsService Tests', () {
    setUp(() {
      LoveStatsService.setMockLoveCount(272000);
      LoveStatsService.setCurrentUser('Vicky');
    });

    test('Initial currentLoveCount returns default value', () {
      expect(LoveStatsService.currentLoveCount, 272000);
    });

    test(
      'watchLoveCount returns in-memory stream in test environment',
      () async {
        final count = await LoveStatsService.watchLoveCount().first;
        expect(count, 272000);
      },
    );

    test('incrementLove increments local count safely in test mode', () async {
      await LoveStatsService.incrementLove(userName: 'Vicky', increment: 1);
      expect(LoveStatsService.currentLoveCount, 272001);

      await LoveStatsService.incrementLove(userName: 'Puja', increment: 1000);
      expect(LoveStatsService.currentLoveCount, 273001);
    });

    test(
      'triggerLoveCelebration emits LoveUpdateEvent with correct partner metadata',
      () async {
        final eventFuture = LoveStatsService.onPartnerLove.first;

        LoveStatsService.triggerLoveCelebration(
          increment: 1000,
          senderName: 'Puja',
          isMegaShower: true,
        );

        final event = await eventFuture;
        expect(event.increment, 1000);
        expect(event.senderName, 'Puja');
        expect(event.isMegaShower, isTrue);
      },
    );
  });
}
