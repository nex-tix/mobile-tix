// File: offline_queue_dao_test.dart
// Unit test untuk OfflineQueueDAO + adaptor Hive QueuedScan (Commit 3.3)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mobile_tix/core/data/dao/offline_queue_dao.dart';
import 'package:mobile_tix/features/scanner/data/models/queued_scan.dart';

void main() {
  group('OfflineQueueDAO Tests', () {
    late OfflineQueueDAO dao;

    setUpAll(() {
      // Init Hive di folder temp + daftarkan adapter QueuedScan
      Hive.init(
        Directory.systemTemp.createTempSync('offline_queue_dao_test').path,
      );
      OfflineQueueDAO.registerAdapters();
    });

    setUp(() async {
      // Ambil singleton DAO lalu buka box ter-typed
      dao = OfflineQueueDAO();
      await dao.initialize();

      // Pastikan antrean kosong sebelum tiap test
      await dao.clear();
    });

    group('enqueue', () {
      test('antrean kosong saat awal', () {
        expect(dao.getAll(), isEmpty);
        expect(dao.size, equals(0));
        expect(dao.hasItems, isFalse);
        expect(dao.first(), isNull);
      });

      test('enqueue menyimpan satu item lengkap dengan field-nya', () async {
        final scan = await dao.enqueue(
          ticketCode: 'TIX-001',
          checkpointId: 'cp-01',
        );

        // Objek balikan harus terisi sesuai input
        expect(scan.ticketCode, equals('TIX-001'));
        expect(scan.checkpointId, equals('cp-01'));
        expect(scan.mode, equals('checkIn')); // default mode
        expect(scan.retryCount, equals(0));

        final items = dao.getAll();
        expect(items.length, equals(1));
        expect(items.first.id, equals(scan.id));
      });

      test('enqueue mendukung mode check (tanpa check-in)', () async {
        await dao.enqueue(
          ticketCode: 'TIX-002',
          checkpointId: 'cp-02',
          mode: 'check',
        );

        expect(dao.first()!.mode, equals('check'));
      });

      test('beberapa item diurutkan FIFO (yang lama di depan)', () async {
        // Buat 3 item dengan timestamp berbeda supaya urutan bisa diuji
        final older = QueuedScan(
          id: 'q-older',
          ticketCode: 'TIX-OLD',
          mode: 'checkIn',
          checkpointId: 'cp-01',
          queuedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
        );
        await dao.save(older);
        await dao.enqueue(ticketCode: 'TIX-NEW', checkpointId: 'cp-01');

        final items = dao.getAll();
        expect(items.length, equals(2));
        // Item yang lebih tua harus di posisi pertama
        expect(items.first.id, equals('q-older'));
      });

      test('enqueue beruntun tidak saling menimpa (ID & urutan unik)', () async {
        // Regresi: ID item diturunkan dari jam perangkat, yang di Windows bisa
        // beresolusi kasar — dua scan beruntun pernah mendapat microsecond yang
        // sama sehingga item kedua menimpa yang pertama.
        await dao.enqueue(ticketCode: 'TIX-RACE-1', checkpointId: 'cp-01');
        await dao.enqueue(ticketCode: 'TIX-RACE-2', checkpointId: 'cp-01');
        await dao.enqueue(ticketCode: 'TIX-RACE-3', checkpointId: 'cp-01');

        final items = dao.getAll();
        expect(items.length, equals(3));
        expect(items.map((scan) => scan.id).toSet().length, equals(3));
        // Urutan FIFO tetap terjaga walau stempel waktunya berdekatan
        expect(
          items.map((scan) => scan.ticketCode).toList(),
          equals(['TIX-RACE-1', 'TIX-RACE-2', 'TIX-RACE-3']),
        );
      });
    });

    group('remove & retry', () {
      test('remove menghapus item yang sudah terkirim', () async {
        final scan = await dao.enqueue(
          ticketCode: 'TIX-003',
          checkpointId: 'cp-01',
        );
        expect(dao.size, equals(1));

        await dao.remove(scan.id);

        expect(dao.size, equals(0));
        expect(dao.hasItems, isFalse);
      });

      test('remove id yang tidak ada tidak melempar error', () async {
        await dao.remove('tidak-ada');
        expect(dao.size, equals(0));
      });

      test('incrementRetry menaikkan counter percobaan kirim', () async {
        final scan = await dao.enqueue(
          ticketCode: 'TIX-004',
          checkpointId: 'cp-01',
        );

        await dao.incrementRetry(scan.id);
        await dao.incrementRetry(scan.id);

        // Nilai retryCount harus persist, bukan hanya berubah di memori
        expect(dao.getAll().first.retryCount, equals(2));
      });
    });

    group('TTL & clear', () {
      test('item lebih tua dari 24 jam dibuang otomatis saat getAll', () async {
        // Simulasi scan kemarin (25 jam lalu) — sudah kedaluwarsa
        await dao.save(
          QueuedScan(
            id: 'q-expired',
            ticketCode: 'TIX-EXPIRED',
            mode: 'checkIn',
            checkpointId: 'cp-01',
            queuedAt: DateTime.now().toUtc().subtract(
              const Duration(hours: 25),
            ),
          ),
        );
        await dao.enqueue(ticketCode: 'TIX-FRESH', checkpointId: 'cp-01');

        final items = dao.getAll();

        // Hanya item yang masih fresh yang dikembalikan
        expect(items.length, equals(1));
        expect(items.first.ticketCode, equals('TIX-FRESH'));
        // Item kedaluwarsa benar-benar dihapus dari storage
        expect(dao.size, equals(1));
        expect(dao.getAll().any((s) => s.id == 'q-expired'), isFalse);
      });

      test('clear mengosongkan seluruh antrean', () async {
        await dao.enqueue(ticketCode: 'TIX-005', checkpointId: 'cp-01');
        await dao.enqueue(ticketCode: 'TIX-006', checkpointId: 'cp-01');
        expect(dao.size, equals(2));

        await dao.clear();

        expect(dao.getAll(), isEmpty);
        expect(dao.hasItems, isFalse);
      });
    });

    group('payload untuk API', () {
      test('toPayload berisi data yang dibutuhkan endpoint scan', () async {
        final scan = await dao.enqueue(
          ticketCode: 'TIX-007',
          checkpointId: 'cp-07',
        );

        final payload = scan.toPayload();
        expect(payload['ticketCode'], equals('TIX-007'));
        expect(payload['checkpointId'], equals('cp-07'));
        expect(payload['mode'], equals('checkIn'));
        expect(payload['scannedAt'], isA<String>());
      });
    });
  });
}
