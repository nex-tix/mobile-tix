// File: checkpoint_dao_test.dart
// Unit test untuk CheckpointDAO (Commit 3.1 — persist gate aktif + cache list)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mobile_tix/core/data/dao/checkpoint_dao.dart';
import 'package:mobile_tix/features/auth/logic/session_state.dart';
import 'package:mobile_tix/features/checkpoint/data/models/checkpoint.dart';

void main() {
  group('CheckpointDAO Tests', () {
    late CheckpointDAO dao;

    // Box Hive yang dipakai CheckpointDAO (harus sama dengan konstanta di DAO)
    const boxName = 'checkpoint_box';

    setUpAll(() {
      // Init Hive di folder temp — aman untuk unit test tanpa Flutter binding
      Hive.init(Directory.systemTemp.createTempSync('checkpoint_dao_test').path);
    });

    setUp(() async {
      // Ambil singleton DAO dan buka box-nya
      dao = CheckpointDAO();
      await dao.initialize();

      // Bersihkan isi box supaya tiap test mulai dari kondisi kosong
      await Hive.box(boxName).clear();
    });

    group('active checkpoint', () {
      test('belum ada gate aktif → getActiveCheckpoint null', () {
        expect(dao.getActiveCheckpoint(), isNull);
        expect(dao.hasActiveCheckpoint(), isFalse);
      });

      test('save lalu get mengembalikan data yang sama', () async {
        // Data gate aktif minimal yang dipakai aplikasi
        final gate = {
          'id': 'cp-01',
          'gate': 'Gate 1',
          'name': 'Pintu Masuk Utara',
          'note': 'Shift pagi',
        };

        await dao.saveCheckpoint(gate);

        // hasActiveCheckpoint harus true setelah disimpan
        expect(dao.hasActiveCheckpoint(), isTrue);

        // Nilai yang dibaca harus identik dengan yang ditulis
        final loaded = dao.getActiveCheckpoint();
        expect(loaded, isNotNull);
        expect(loaded!['id'], equals('cp-01'));
        expect(loaded['gate'], equals('Gate 1'));
        expect(loaded['name'], equals('Pintu Masuk Utara'));
      });

      test('save ulang menimpa gate sebelumnya (tidak menumpuk)', () async {
        await dao.saveCheckpoint({'id': 'cp-01', 'gate': 'Gate 1'});
        await dao.saveCheckpoint({'id': 'cp-02', 'gate': 'Gate 2'});

        final loaded = dao.getActiveCheckpoint();
        expect(loaded!['id'], equals('cp-02'));
      });

      test('clearActiveCheckpoint menghapus gate aktif', () async {
        await dao.saveCheckpoint({'id': 'cp-01', 'gate': 'Gate 1'});
        expect(dao.hasActiveCheckpoint(), isTrue);

        await dao.clearActiveCheckpoint();

        expect(dao.getActiveCheckpoint(), isNull);
        expect(dao.hasActiveCheckpoint(), isFalse);
      });

      test('Checkpoint model toJson dan fromJson roundtrip', () {
        const cp = Checkpoint(
          id: 'cp-01',
          gate: 'Gate 1',
          name: 'Pintu Utama',
          note: 'Shift pagi',
        );
        final json = cp.toJson();
        final restored = Checkpoint.fromJson(json);
        expect(restored.id, equals(cp.id));
        expect(restored.gate, equals(cp.gate));
        expect(restored.name, equals(cp.name));
      });

      test('SessionState selectCheckpoint menyimpan ke DAO dan di-restore', () async {
        final session = SessionState();
        const cp = Checkpoint(
          id: 'cp-99',
          gate: 'Gate VIP',
          name: 'Pintu VIP',
          note: 'Shift malam',
        );
        await session.selectCheckpoint(cp);
        expect(dao.hasActiveCheckpoint(), isTrue);
        final loaded = dao.getActiveCheckpoint();
        expect(loaded?['id'], equals('cp-99'));

        // Instance baru otomatis me-restore gate aktif
        final freshSession = SessionState();
        expect(freshSession.checkpoint?.id, equals('cp-99'));
        expect(freshSession.checkpoint?.gate, equals('Gate VIP'));

        // Sign out menghapus checkpoint
        await session.signOut();
        expect(dao.hasActiveCheckpoint(), isFalse);
      });
    });

    group('checkpoint list cache', () {
      test('cache valid setelah saveCheckpoints', () async {
        await dao.saveCheckpoints([
          {'id': 'cp-01', 'name': 'Gate 1'},
          {'id': 'cp-02', 'name': 'Gate 2'},
        ]);

        // isCacheValid true karena timestamp baru saja ditulis
        expect(dao.isCacheValid(), isTrue);

        final list = dao.getCheckpoints();
        expect(list, isNotNull);
        expect(list!.length, equals(2));
        expect(list.first['name'], equals('Gate 1'));
      });

      test('belum pernah save → cache tidak valid dan list null', () {
        expect(dao.isCacheValid(), isFalse);
        expect(dao.getCheckpoints(), isNull);
      });

      test('clear() menghapus cache tapi TIDAK menghapus gate aktif', () async {
        await dao.saveCheckpoints([
          {'id': 'cp-01', 'name': 'Gate 1'},
        ]);
        await dao.saveCheckpoint({'id': 'cp-01', 'gate': 'Gate 1'});

        await dao.clear();

        // Cache list hilang
        expect(dao.getCheckpoints(), isNull);
        expect(dao.isCacheValid(), isFalse);
        // Gate aktif tetap tersimpan — refresh cache tidak boleh mengganggu shift
        expect(dao.hasActiveCheckpoint(), isTrue);
      });
    });
  });
}
