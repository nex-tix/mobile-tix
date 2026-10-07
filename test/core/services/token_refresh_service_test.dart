import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/core/services/token_refresh_service.dart';

void main() {
  group('TokenRefreshService Tests', () {
    // Dummy JWT with exp in the future
    // Header: {"alg":"HS256","typ":"JWT"}
    // Payload: {"sub":"admin.gate","exp":1893456000} (around year 2030)
    const validFutureJwt =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZG1pbi5nYXRlIiwiZXhwIjoxODkzNDU2MDAwfQ.dummySignature';

    test('getExpiryDate extracts correct DateTime from JWT', () {
      final service = TokenRefreshService();
      final expiry = service.getExpiryDate(validFutureJwt);

      expect(expiry, isNotNull);
      expect(expiry!.isAfter(DateTime(2025, 1, 1)), isTrue);
    });

    test('isExpired returns false for future token and true for past token', () {
      final service = TokenRefreshService();
      expect(service.isExpired(validFutureJwt), isFalse);

      // Expired token (exp in 2018)
      const expiredJwt =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZG1pbi5nYXRlIiwiZXhwIjoxNTE2MjM5MDIyfQ.dummySignature';
      expect(service.isExpired(expiredJwt), isTrue);
    });

    test('scheduleNextRefresh and cancel', () {
      final service = TokenRefreshService();
      service.scheduleNextRefresh(validFutureJwt);

      expect(service.isScheduled, isTrue);

      service.cancel();
      expect(service.isScheduled, isFalse);
    });
  });
}
