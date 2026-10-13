// File: history_repository_test.dart
// Unit test DashboardRepository bagian riwayat: paginasi & filter lewat mock API.

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/core/constants/ticket_status.dart';
import 'package:mobile_tix/core/data/repositories/dashboard_repository.dart';
import 'package:mobile_tix/core/error/api_failure.dart';
import 'package:mobile_tix/core/services/api_service.dart';
import 'package:mobile_tix/core/services/encryption_service.dart';

void main() {
  group('DashboardRepository.getTicketHistory (mock API)', () {
    late DashboardRepository repository;

    /// Tanggal hari ini dalam format yang dipakai query param.
    String dayParam(DateTime date) {
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      return '${date.year}-$month-$day';
    }

    setUpAll(() {
      EncryptionService.initialize();
    });

    setUp(() {
      // Mock diaktifkan eksplisit (EnvConfig.useMockApi bawaannya false).
      repository = DashboardRepositoryImpl(ApiService(useMockApi: true));
    });

    test('halaman pertama mengembalikan satu halaman penuh', () async {
      final page = await repository.getTicketHistory(page: 1, pageSize: 10);

      expect(page.page, 1);
      expect(page.pageSize, 10);
      expect(page.items.length, 10);
      expect(page.totalItems, 27);
      expect(page.totalPages, 3);
      expect(page.hasMore, isTrue);
    });

    test('halaman terakhir lebih pendek dan tidak punya lanjutan', () async {
      final page = await repository.getTicketHistory(page: 3, pageSize: 10);

      expect(page.items.length, 7);
      expect(page.page, 3);
      expect(page.hasMore, isFalse);
    });

    test('halaman di luar jangkauan mengembalikan daftar kosong', () async {
      final page = await repository.getTicketHistory(page: 9, pageSize: 10);

      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('riwayat terbaru di atas dan tidak ada baris kembar antar halaman',
        () async {
      final first = await repository.getTicketHistory(page: 1, pageSize: 10);
      final second = await repository.getTicketHistory(page: 2, pageSize: 10);

      // Urutan menurun menurut waktu scan.
      for (var i = 1; i < first.items.length; i++) {
        expect(
          first.items[i - 1].scannedAt.isAfter(first.items[i].scannedAt),
          isTrue,
          reason: 'baris ke-$i harus lebih tua dari baris sebelumnya',
        );
      }

      final overlap = first.items
          .map((record) => record.identity)
          .toSet()
          .intersection(second.items.map((record) => record.identity).toSet());
      expect(overlap, isEmpty);
    });

    test('tiap baris riwayat terparsing lengkap', () async {
      final page = await repository.getTicketHistory(page: 1, pageSize: 10);

      for (final record in page.items) {
        expect(record.ticketCode, isNotEmpty);
        expect(record.checkpoint, isNotNull);
        expect(record.validatedBy, 'Admin Gate');
        expect(record.scannedAt.year, greaterThan(2000));
      }
    });

    test('filter status menyaring sesuai verdict yang diminta', () async {
      final valid = await repository.getTicketHistory(
        page: 1,
        pageSize: 50,
        status: TicketStatus.valid.code,
      );
      final cancelled = await repository.getTicketHistory(
        page: 1,
        pageSize: 50,
        status: TicketStatus.cancelled.code,
      );

      expect(valid.totalItems, 6);
      expect(
        valid.items.every((record) => record.status == TicketStatus.valid),
        isTrue,
      );
      expect(cancelled.totalItems, 5);
      expect(
        cancelled.items.every(
          (record) => record.status == TicketStatus.cancelled,
        ),
        isTrue,
      );
    });

    test('filter gate hanya mengembalikan gate itu', () async {
      final page = await repository.getTicketHistory(
        page: 1,
        pageSize: 50,
        checkpoint: 'Gate A',
      );

      expect(page.totalItems, 7);
      expect(
        page.items.every((record) => record.checkpoint == 'Gate A'),
        isTrue,
      );
    });

    test('filter tanggal hanya mengembalikan hari itu', () async {
      final now = DateTime.now();
      final expectedDate = DateTime(now.year, now.month, now.day);
      final page = await repository.getTicketHistory(
        page: 1,
        pageSize: 50,
        date: dayParam(now),
      );

      expect(page.totalItems, 9);
      expect(
        page.items.every((record) => record.scanDate == expectedDate),
        isTrue,
      );
    });

    test('filter gabungan (tanggal + status) mempersempit lebih jauh',
        () async {
      final page = await repository.getTicketHistory(
        page: 1,
        pageSize: 50,
        date: dayParam(DateTime.now()),
        status: TicketStatus.valid.code,
      );

      expect(page.totalItems, 2);
      expect(
        page.items.every((record) => record.status == TicketStatus.valid),
        isTrue,
      );
    });

    test('periode tanpa hasil bukan kegagalan', () async {
      final page = await repository.getTicketHistory(
        page: 1,
        pageSize: 10,
        date: '2000-01-01',
      );

      expect(page.items, isEmpty);
      expect(page.totalItems, 0);
      expect(page.totalPages, 0);
      expect(page.hasMore, isFalse);
    });

    test('page dan pageSize tidak wajar ditolak sebelum request dikirim',
        () async {
      await expectLater(
        repository.getTicketHistory(page: 0),
        throwsA(
          isA<ApiFailure>().having(
            (failure) => failure.kind,
            'kind',
            ApiFailureKind.server,
          ),
        ),
      );

      await expectLater(
        repository.getTicketHistory(pageSize: 999),
        throwsA(isA<ApiFailure>()),
      );
    });

    test('pageSize menentukan besar halaman yang diminta', () async {
      final page = await repository.getTicketHistory(page: 1, pageSize: 5);

      expect(page.items.length, 5);
      expect(page.pageSize, 5);
      expect(page.totalPages, 6); // 27 / 5 dibulatkan ke atas
    });
  });
}
