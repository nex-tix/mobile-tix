import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/core/services/api_service.dart';
import 'package:mobile_tix/core/services/encryption_service.dart';

class _Mock401Adapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"success":false,"message":"Unauthorized"}',
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('ApiService Tests', () {
    setUpAll(() {
      EncryptionService.initialize();
    });

    test('ApiService mock login request succeeds with valid credentials', () async {
      final apiService = ApiService(useMockApi: true);

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
      final apiService = ApiService(useMockApi: true);
      expect(apiService.token, isNull);

      apiService.setToken('test-token-123');
      expect(apiService.token, equals('test-token-123'));

      apiService.clearToken();
      expect(apiService.token, isNull);
    });

    test('ApiService mock checkpoints returns list', () async {
      final apiService = ApiService(useMockApi: true);
      final response = await apiService.get('/checkpoints');

      expect(response.statusCode, equals(200));
      final data = response.data as Map<String, dynamic>;
      expect(data['success'], isTrue);
      expect(data['data'], isA<List>());
    });

    test('401 pada endpoint publik atau tanpa token tidak memicu refresh atau session expired', () async {
      final apiService = ApiService(useMockApi: false);
      apiService.dio.httpClientAdapter = _Mock401Adapter();
      bool refreshCalled = false;
      bool sessionExpiredCalled = false;

      apiService.onRefreshToken = () async {
        refreshCalled = true;
        return null;
      };
      apiService.onSessionExpired = () {
        sessionExpiredCalled = true;
      };

      try {
        await apiService.get('/checkpoints');
      } catch (_) {}

      expect(refreshCalled, isFalse);
      expect(sessionExpiredCalled, isFalse);
    });

    test('401 pada endpoint terproteksi saat memiliki token memicu refresh dan session expired jika refresh gagal', () async {
      final apiService = ApiService(useMockApi: false);
      apiService.dio.httpClientAdapter = _Mock401Adapter();
      apiService.setToken('existing-valid-token');
      bool refreshCalled = false;
      bool sessionExpiredCalled = false;

      apiService.onRefreshToken = () async {
        refreshCalled = true;
        return null;
      };
      apiService.onSessionExpired = () {
        sessionExpiredCalled = true;
      };

      try {
        await apiService.get('/ticket/history');
      } catch (_) {}

      expect(refreshCalled, isTrue);
      expect(sessionExpiredCalled, isTrue);
    });
  });
}
