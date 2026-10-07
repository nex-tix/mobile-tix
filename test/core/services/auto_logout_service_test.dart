import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/core/services/auto_logout_service.dart';

void main() {
  group('AutoLogoutService Tests', () {
    test('resetTimer sets active warning on timeout', () async {
      bool warningTriggered = false;
      bool logoutTriggered = false;

      final service = AutoLogoutService(
        idleDuration: const Duration(milliseconds: 60),
        warningDuration: const Duration(milliseconds: 30),
        onShowWarning: () {
          warningTriggered = true;
        },
        onForceLogout: () {
          logoutTriggered = true;
        },
      );

      service.resetTimer();
      expect(warningTriggered, isFalse);

      // Wait until warning fires (60ms - 30ms = 30ms)
      await Future.delayed(const Duration(milliseconds: 40));
      expect(warningTriggered, isTrue);
      expect(service.isWarningActive, isTrue);
      expect(logoutTriggered, isFalse);

      // Wait until forced logout fires (30ms more)
      await Future.delayed(const Duration(milliseconds: 40));
      expect(logoutTriggered, isTrue);
    });

    test('stayLoggedIn resets warning and timer', () async {
      bool warningDismissed = false;

      final service = AutoLogoutService(
        idleDuration: const Duration(milliseconds: 50),
        warningDuration: const Duration(milliseconds: 25),
        onDismissWarning: () {
          warningDismissed = true;
        },
      );

      service.resetTimer();
      await Future.delayed(const Duration(milliseconds: 30));
      expect(service.isWarningActive, isTrue);

      await service.stayLoggedIn();
      expect(service.isWarningActive, isFalse);
      expect(warningDismissed, isTrue);

      service.stop();
    });
  });
}
