// File: scan_record_test.dart
// Unit test model riwayat: ScanRecord, ScanRecordPage, dan HistoryFilter.

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/core/constants/ticket_status.dart';
import 'package:mobile_tix/features/history/data/models/history_filter.dart';
import 'package:mobile_tix/features/history/data/models/scan_record.dart';
import 'package:mobile_tix/features/history/data/models/scan_record_page.dart';

void main() {
  group('ScanRecord.fromJson', () {
    test('membaca kontrak riwayat lengkap', () {
      final record = ScanRecord.fromJson({
        'ticket_code': 'TKT-2026-001245',
        'status': 'valid',
        'scanned_at': '2026-10-08T09:15:00.000',
        'checkpoint': 'Gate A',
        'visitor_name': 'Rangga Prasetyo',
        'visitor_count': 2,
        'category': 'Rombongan',
        'validated_by': 'Admin Gate',
      });

      expect(record.ticketCode, 'TKT-2026-001245');
      expect(record.status, TicketStatus.valid);
      expect(record.scannedAt, DateTime(2026, 10, 8, 9, 15));
      expect(record.checkpoint, 'Gate A');
      expect(record.visitorName, 'Rangga Prasetyo');
      expect(record.visitorCount, 2);
      expect(record.category, 'Rombongan');
      expect(record.validatedBy, 'Admin Gate');
      expect(record.isValid, isTrue);
      expect(record.isRejected, isFalse);
    });

    test('menerima camelCase dan nama field alternatif', () {
      final record = ScanRecord.fromJson({
        'ticketCode': 'TKT-2',
        'status': 'already_used',
        'checkInTime': '2026-10-08T09:15:00.000',
        'checkpointName': 'Gate B',
        'buyerName': 'Nadia Kusuma',
        'visitorCount': 3,
        'ticketType': 'VIP',
        'validatorName': 'Petugas 2',
      });

      expect(record.ticketCode, 'TKT-2');
      expect(record.status, TicketStatus.alreadyUsed);
      expect(record.checkpoint, 'Gate B');
      expect(record.visitorName, 'Nadia Kusuma');
      expect(record.visitorCount, 3);
      expect(record.category, 'VIP');
      expect(record.validatedBy, 'Petugas 2');
      expect(record.isRejected, isTrue);
    });

    test('payload kosong tetap menghasilkan baris yang bisa digambar', () {
      final record = ScanRecord.fromJson(const <String, dynamic>{});

      expect(record.ticketCode, isEmpty);
      expect(record.status, TicketStatus.notFound);
      expect(record.visitorCount, 1); // default
      expect(record.checkpoint, isNull);
      expect(record.visitorName, isNull);
    });

    test('identity menggabungkan kode tiket dan waktu scan', () {
      final a = ScanRecord(
        ticketCode: 'TKT-1',
        status: TicketStatus.valid,
        scannedAt: DateTime(2026, 10, 8, 9),
      );
      final same = ScanRecord(
        ticketCode: 'TKT-1',
        status: TicketStatus.valid,
        scannedAt: DateTime(2026, 10, 8, 9),
      );
      final later = ScanRecord(
        ticketCode: 'TKT-1',
        status: TicketStatus.valid,
        scannedAt: DateTime(2026, 10, 8, 10),
      );

      expect(a.identity, same.identity);
      expect(a.identity, isNot(later.identity));
      // Kesetaraan nilai, dipakai untuk menyaring duplikat antar halaman.
      expect(a, equals(same));
      expect(a, isNot(equals(later)));
    });

    test('scanDate membuang jam', () {
      final record = ScanRecord(
        ticketCode: 'TKT-1',
        status: TicketStatus.valid,
        scannedAt: DateTime(2026, 10, 8, 23, 59, 59),
      );

      expect(record.scanDate, DateTime(2026, 10, 8));
    });
  });

  group('ScanRecordPage.fromJson', () {
    test('membaca payload snake_case dan memparsing barisnya', () {
      final page = ScanRecordPage.fromJson(
        {
          'current_page': 2,
          'per_page': 10,
          'total_items': 27,
          'total_pages': 3,
          'items': [
            {
              'ticket_code': 'TKT-1',
              'status': 'valid',
              'scanned_at': '2026-10-08T09:00:00.000',
            },
            {
              'ticket_code': 'TKT-2',
              'status': 'expired',
              'scanned_at': '2026-10-08T08:00:00.000',
            },
          ],
        },
        page: 1,
        pageSize: 10,
      );

      expect(page.page, 2);
      expect(page.pageSize, 10);
      expect(page.totalItems, 27);
      expect(page.totalPages, 3);
      expect(page.items.length, 2);
      expect(page.items.first.ticketCode, 'TKT-1');
      expect(page.hasMore, isTrue);
      expect(page.isEmpty, isFalse);
    });

    test('halaman terakhir tidak lagi punya lanjutan', () {
      final page = ScanRecordPage.fromJson(
        const {'current_page': 3, 'per_page': 10, 'total_pages': 3, 'items': []},
        page: 3,
        pageSize: 10,
      );

      expect(page.hasMore, isFalse);
      expect(page.isEmpty, isTrue);
    });

    test('tanpa total_pages, halaman penuh dianggap masih ada lanjutan', () {
      final full = ScanRecordPage.fromJson(
        {
          'items': [
            for (var i = 0; i < 10; i++)
              {'ticket_code': 'TKT-$i', 'status': 'valid'},
          ],
        },
        page: 1,
        pageSize: 10,
      );
      final short = ScanRecordPage.fromJson(
        {
          'items': [
            {'ticket_code': 'TKT-1', 'status': 'valid'},
          ],
        },
        page: 2,
        pageSize: 10,
      );

      expect(full.hasMore, isTrue);
      expect(short.hasMore, isFalse);
    });

    test('payload kosong menghasilkan halaman kosong tanpa error', () {
      final page = ScanRecordPage.fromJson(
        const <String, dynamic>{},
        page: 1,
        pageSize: 10,
      );

      expect(page.items, isEmpty);
      expect(page.page, 1);
      expect(page.pageSize, 10);
      expect(page.totalItems, 0);
      expect(page.hasMore, isFalse);
    });
  });

  group('HistoryFilter', () {
    test('none tidak menyaring apa pun', () {
      expect(HistoryFilter.none.isUnfiltered, isTrue);
      expect(HistoryFilter.none.statusParam, isNull);
      expect(HistoryFilter.none.dateParam, isNull);
    });

    test('mengirim kode status yang dipakai API', () {
      const filter = HistoryFilter(status: TicketStatus.alreadyUsed);

      expect(filter.statusParam, 'already_used');
      expect(filter.isUnfiltered, isFalse);
    });

    test('kelompok "ditolak" memakai nilai kelompok, bukan satu verdict', () {
      expect(HistoryFilter.rejected.statusParam, 'rejected');
      expect(HistoryFilter.rejected.rejectedOnly, isTrue);
      expect(HistoryFilter.rejected.isUnfiltered, isFalse);
    });

    test('withRejectedOnly melepas penyaring status pasti', () {
      const filter = HistoryFilter(status: TicketStatus.expired);

      final rejected = filter.withRejectedOnly();

      expect(rejected.status, isNull);
      expect(rejected.rejectedOnly, isTrue);
      expect(rejected.statusParam, 'rejected');
    });

    test('withStatus melepas penyaring kelompok', () {
      final exact = HistoryFilter.rejected.withStatus(TicketStatus.valid);

      expect(exact.rejectedOnly, isFalse);
      expect(exact.statusParam, 'valid');
    });

    test('dateParam memformat tanggal sebagai YYYY-MM-DD', () {
      const filter = HistoryFilter(date: null);

      expect(filter.dateParam, isNull);
      expect(
        HistoryFilter(date: DateTime(2026, 1, 7)).dateParam,
        '2026-01-07',
      );
    });

    test('withX mengganti satu penyaring tanpa menyentuh yang lain', () {
      const base = HistoryFilter(
        status: TicketStatus.valid,
        checkpoint: 'Gate A',
      );

      final withDate = base.withDate(DateTime(2026, 10, 8));

      expect(withDate.status, TicketStatus.valid);
      expect(withDate.checkpoint, 'Gate A');
      expect(withDate.dateParam, '2026-10-08');
      // Objek asal tidak berubah.
      expect(base.date, isNull);
    });

    test('withStatus(null) melepas penyaring status', () {
      const filter = HistoryFilter(status: TicketStatus.expired);

      expect(filter.withStatus(null).isUnfiltered, isTrue);
    });

    test('kesetaraan nilai dipakai cubit untuk menghindari request sia-sia', () {
      const a = HistoryFilter(status: TicketStatus.valid, checkpoint: 'Gate A');
      const b = HistoryFilter(status: TicketStatus.valid, checkpoint: 'Gate A');
      const c = HistoryFilter(status: TicketStatus.valid, checkpoint: 'Gate B');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
