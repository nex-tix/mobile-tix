// File: checkpoint_repository_test.dart
// Unit test CheckpointRepository (Commit 7.1) dengan ApiService, CheckpointDAO, & OfflineQueueDAO

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mobile_tix/core/data/dao/checkpoint_dao.dart';
import 'package:mobile_tix/core/data/dao/offline_queue_dao.dart';
import 'package:mobile_tix/core/data/repositories/checkpoint_repository.dart';
import 'package:mobile_tix/core/services/api_service.dart';
import 'package:mobile_tix/core/services/encryption_service.dart';

void main() {
  group('CheckpointRepository Tests', () {
    late ApiService apiService;
    late CheckpointDAO checkpointDAO;
    late OfflineQueueDAO offlineQueueDAO;
    late CheckpointRepository repository;

    setUpAll(() {
      EncryptionService.initialize();
      Hive.init(Directory.systemTemp.createTempSync('cp_repo_test').path);
      OfflineQueueDAO.registerAdapters();
    });

    setUp(() async {
      checkpointDAO = CheckpointDAO();
      await checkpointDAO.initialize();
      await checkpointDAO.clear();

      offlineQueueDAO = OfflineQueueDAO();
      await offlineQueueDAO.initialize();
      await offlineQueueDAO.clear();

      apiService = ApiService(useMockApi: true);
      repository = CheckpointRepository(
        apiService,
        checkpointDAO,
        offlineQueueDAO,
      );
    });

    test('getCheckpoints memuat daftar gate dan menyimpannya ke cache', () async {
      expect(checkpointDAO.isCacheValid(), isFalse);

      final checkpoints = await repository.getCheckpoints();

      expect(checkpoints, isNotEmpty);
      expect(checkpoints.any((c) => c.name.contains('Gate A')), isTrue);
      expect(checkpointDAO.isCacheValid(), isTrue);
    });

    test('getCheckpoints memakai cache jika cache valid dan bukan forceRefresh', () async {
      // Simpan dummy checkpoint di cache
      await checkpointDAO.saveCheckpoints([
        {'id': 'cached-01', 'name': 'Gate Cached'},
      ]);

      final checkpoints = await repository.getCheckpoints();

      expect(checkpoints.length, equals(1));
      expect(checkpoints.first.id, equals('cached-01'));
      expect(checkpoints.first.name, equals('Gate Cached'));
    });

    test('getCheckpoints dengan forceRefresh memuat ulang dari API', () async {
      await checkpointDAO.saveCheckpoints([
        {'id': 'cached-01', 'name': 'Gate Cached'},
      ]);

      final checkpoints = await repository.getCheckpoints(forceRefresh: true);

      expect(checkpoints.length, greaterThan(1));
      expect(checkpoints.any((c) => c.name.contains('Gate A')), isTrue);
    });

    test('clearCache mengosongkan cache DAO', () async {
      await checkpointDAO.saveCheckpoints([
        {'id': 'cached-01', 'name': 'Gate Cached'},
      ]);
      expect(checkpointDAO.isCacheValid(), isTrue);

      await repository.clearCache();

      expect(checkpointDAO.isCacheValid(), isFalse);
    });

    test('checkTicket dengan kode valid mengembalikan TicketCheckResponse', () async {
      final result = await repository.checkTicket('TKT-2026-001245');

      expect(result.ticketCode, isNotEmpty);
      expect(result.status, isNotEmpty);
    });

    test('checkTicket dengan kode kosong melempar Exception', () async {
      expect(
        () => repository.checkTicket(''),
        throwsA(isA<Exception>()),
      );
    });

    test('validateAndCheckin dengan parameter kosong melempar Exception', () async {
      expect(
        () => repository.validateAndCheckin(ticketId: '', checkpointId: ''),
        throwsA(isA<Exception>()),
      );
    });
  });
}
