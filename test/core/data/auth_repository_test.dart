// File: auth_repository_test.dart
// Unit test AuthRepository (Commit 7.1) dengan ApiService & TokenJwtDAO

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mobile_tix/core/data/dao/token_jwt_dao.dart';
import 'package:mobile_tix/core/data/repositories/auth_repository.dart';
import 'package:mobile_tix/core/services/api_service.dart';
import 'package:mobile_tix/core/services/encryption_service.dart';

void main() {
  group('AuthRepository Tests', () {
    late ApiService apiService;
    late TokenJwtDAO tokenDAO;
    late AuthRepository repository;

    const boxName = 'token_box';

    setUpAll(() {
      EncryptionService.initialize();
      Hive.init(Directory.systemTemp.createTempSync('auth_repo_test').path);
    });

    setUp(() async {
      tokenDAO = TokenJwtDAO();
      await tokenDAO.initialize();
      await Hive.box<String>(boxName).clear();

      apiService = ApiService(useMockApi: true);
      repository = AuthRepository(apiService, tokenDAO);
    });

    test('login berhasil dengan valid credentials dan menyimpan token ke DAO', () async {
      expect(repository.isAuthenticated(), isFalse);

      final response = await repository.login(
        username: 'admin.gate',
        password: 'gate2026',
      );

      expect(response.token, isNotEmpty);
      expect(response.name, equals('Admin Gate'));
      expect(repository.isAuthenticated(), isTrue);
      expect(tokenDAO.getToken(), equals(response.token));
      expect(apiService.token, equals(response.token));
    });

    test('login gagal melempar Exception jika credentials salah', () async {
      expect(
        () => repository.login(
          username: 'wrong.user',
          password: 'wrongpassword',
        ),
        throwsA(isA<Exception>()),
      );

      expect(repository.isAuthenticated(), isFalse);
    });

    test('login dengan username/password kosong ditolak sebelum request', () async {
      expect(
        () => repository.login(username: '', password: ''),
        throwsA(isA<Exception>()),
      );
    });

    test('me mengembalikan info current user saat token tersedia', () async {
      // Login terlebih dahulu untuk mengisi token
      await repository.login(
        username: 'admin.gate',
        password: 'gate2026',
      );

      final user = await repository.me();
      expect(user.name, equals('Admin Gate'));
      expect(user.email, equals('admin.gate@example.com'));
      expect(user.role, equals('validator'));
    });

    test('me melempar Exception saat belum login / token kosong', () async {
      await tokenDAO.deleteToken();
      apiService.clearToken();

      expect(
        () => repository.me(),
        throwsA(isA<Exception>()),
      );
    });

    test('logout menghapus token lokal dan membersihkan ApiService', () async {
      await repository.login(
        username: 'admin.gate',
        password: 'gate2026',
      );
      expect(repository.isAuthenticated(), isTrue);

      await repository.logout();

      expect(repository.isAuthenticated(), isFalse);
      expect(tokenDAO.getToken(), isNull);
      expect(apiService.token, isNull);
    });
  });
}
