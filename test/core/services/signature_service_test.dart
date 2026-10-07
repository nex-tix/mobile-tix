import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/core/services/signature_service.dart';

void main() {
  group('SignatureService Tests', () {
    test('Hash body generates consistent sha256 hex string', () {
      const body = '{"username":"admin.gate","password":"gate2026"}';
      final hash1 = SignatureService.hashBody(body);
      final hash2 = SignatureService.hashBody(body);

      expect(hash1, isNotEmpty);
      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64)); // SHA256 hex length
    });

    test('Empty body produces empty hash', () {
      expect(SignatureService.hashBody(''), equals(''));
    });

    test('Sign produces valid base64 signature', () {
      final sig = SignatureService.sign(
        method: 'POST',
        endpoint: '/login',
        token: '',
        hashedBody: SignatureService.hashBody('{"test":true}'),
        timestamp: '2026-10-07T12:00:00.000Z',
      );

      expect(sig, isNotEmpty);
      // Valid base64
      expect(RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(sig), isTrue);
    });

    test('signRequest convenience method matches sign', () {
      const timestamp = '2026-10-07T12:00:00.000Z';
      const body = '{"hello":"world"}';

      final sig1 = SignatureService.signRequest(
        method: 'POST',
        endpoint: '/ticket/check',
        token: 'test-token',
        body: body,
        timestamp: timestamp,
      );

      final sig2 = SignatureService.sign(
        method: 'POST',
        endpoint: '/ticket/check',
        token: 'test-token',
        hashedBody: SignatureService.hashBody(body),
        timestamp: timestamp,
      );

      expect(sig1, equals(sig2));
    });
  });
}
