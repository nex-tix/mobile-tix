import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/core/services/api_service.dart';
import 'package:mobile_tix/core/services/encryption_service.dart';

void main() {
  group('ApiService Tests', () {
    setUpAll(() {
      EncryptionService.initialize();
    });

    test('ApiService mock login request succeeds with valid credentials', () async {
      final apiService = ApiService();

      final response = await apiService.post(
        '/login',
        data: {
          'username': 'admin.gate',
          'password': 'gate2026',
          'checkpoint': 'Gate A',
        },
      );

      expect(response.statusCode, equals(200));
      expect(response.data, isA<Map<String, dynamic>>());
      final data = response.data as Map<String, dynamic>;
      expect(data['success'], isTrue);
      expect(data['data']['token'], isNotEmpty);
    });

    test('ApiService sets and clears token properly', () {
      final apiService = ApiService();
      expect(apiService.token, isNull);

      apiService.setToken('test-token-123');
      expect(apiService.token, equals('test-token-123'));

      apiService.clearToken();
      expect(apiService.token, isNull);
    });

    test('ApiService mock checkpoints returns list', () async {
      final apiService = ApiService();
      final response = await apiService.get('/checkpoints');

      expect(response.statusCode, equals(200));
      final data = response.data as Map<String, dynamic>;
      expect(data['success'], isTrue);
      expect(data['data'], isA<List>());
    });
  });
}
