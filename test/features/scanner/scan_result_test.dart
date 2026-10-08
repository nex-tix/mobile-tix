// File: scan_result_test.dart
// Unit test model ScanResult (parsing payload API → 5 verdict gate).

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/core/constants/ticket_status.dart';
import 'package:mobile_tix/features/scanner/data/models/scan_result.dart';

void main() {
  group('ScanResult.parseStatus', () {
    test('memetakan kelima status resmi', () {
      expect(ScanResult.parseStatus('valid'), TicketStatus.valid);
      expect(ScanResult.parseStatus('already_used'), TicketStatus.alreadyUsed);
      expect(ScanResult.parseStatus('expired'), TicketStatus.expired);
      expect(ScanResult.parseStatus('not_found'), TicketStatus.notFound);
      expect(ScanResult.parseStatus('cancelled'), TicketStatus.cancelled);
    });

    test('toleran terhadap variasi penulisan dari backend', () {
      expect(ScanResult.parseStatus(' VALID '), TicketStatus.valid);
      expect(ScanResult.parseStatus('ALREADY_USED'), TicketStatus.alreadyUsed);
      expect(ScanResult.parseStatus('checked_in'), TicketStatus.valid);
      expect(ScanResult.parseStatus('used'), TicketStatus.alreadyUsed);
      expect(ScanResult.parseStatus('void'), TicketStatus.cancelled);
    });

    test('status tak dikenal/null dianggap notFound, bukan crash', () {
      expect(ScanResult.parseStatus(null), TicketStatus.notFound);
      expect(ScanResult.parseStatus(''), TicketStatus.notFound);
      expect(ScanResult.parseStatus('entah_apa'), TicketStatus.notFound);
    });
  });

  group('ScanResult.fromJson', () {
    test('membaca kontrak snake_case lengkap', () {
      final result = ScanResult.fromJson(
        {
          'status': 'already_used',
          'ticket_code': 'VALID-1',
          'visitor_name': 'Nadia Kusuma',
          'visitor_count': 2,
          'category': 'Rombongan',
          'used_at': '2026-10-07T05:30:00.000Z',
          'used_by': 'Admin Gate',
          'used_at_checkpoint': 'Gate B',
          'expiry_date': '2026-10-07',
          'message': 'Tiket sudah pernah digunakan',
        },
        mode: ScanMode.checkIn,
        scannedAt: DateTime(2026, 10, 7, 12, 30),
      );

      expect(result.status, TicketStatus.alreadyUsed);
      expect(result.ticketCode, 'VALID-1');
      expect(result.visitorName, 'Nadia Kusuma');
      expect(result.visitorCount, 2);
      expect(result.category, 'Rombongan');
      expect(result.usedBy, 'Admin Gate');
      expect(result.usedAtCheckpoint, 'Gate B');
      expect(result.usedAt, isNotNull);
      expect(result.expiryDate, isNotNull);
      expect(result.message, 'Tiket sudah pernah digunakan');
      expect(result.mode, ScanMode.checkIn);
      expect(result.scannedAt, DateTime(2026, 10, 7, 12, 30));
    });

    test('menerima camelCase dan field alternatif', () {
      final result = ScanResult.fromJson(
        {
          'status': 'valid',
          'ticketCode': 'TKT-1',
          'visitorName': 'Sari Melati',
          'visitorCount': 3,
          'visitor_type': 'VIP',
          'check_in_time': '2026-10-07T05:31:00.000Z',
          'validator_name': 'Admin Gate',
          'checkpoint': 'Gate A',
          'event_date': '2026-10-08',
        },
        mode: ScanMode.check,
      );

      expect(result.status, TicketStatus.valid);
      expect(result.ticketCode, 'TKT-1');
      expect(result.visitorName, 'Sari Melati');
      expect(result.visitorCount, 3);
      expect(result.category, 'VIP');
      expect(result.usedAt, isNotNull);
      expect(result.usedBy, 'Admin Gate');
      expect(result.usedAtCheckpoint, 'Gate A');
      expect(result.expiryDate, isNotNull);
    });

    test('payload kosong tetap menghasilkan verdict notFound', () {
      final result = ScanResult.fromJson(
        const <String, dynamic>{},
        mode: ScanMode.check,
      );

      expect(result.status, TicketStatus.notFound);
      expect(result.ticketCode, isEmpty);
      expect(result.visitorCount, 1); // default
      expect(result.hasHolder, isFalse);
    });
  });

  group('ScanResult turunan', () {
    test('isValid & isCheckedIn mengikuti status dan mode', () {
      final checkedIn = ScanResult.fromJson(
        const {'status': 'valid', 'ticket_code': 'TKT-1'},
        mode: ScanMode.checkIn,
      );
      expect(checkedIn.isValid, isTrue);
      expect(checkedIn.isCheckedIn, isTrue);

      final checked = ScanResult.fromJson(
        const {'status': 'valid', 'ticket_code': 'TKT-2'},
        mode: ScanMode.check,
      );
      expect(checked.isValid, isTrue);
      expect(checked.isCheckedIn, isFalse);

      final used = ScanResult.fromJson(
        const {'status': 'already_used', 'ticket_code': 'TKT-3'},
        mode: ScanMode.checkIn,
      );
      expect(used.isValid, isFalse);
      expect(used.isCheckedIn, isFalse);
    });

    test('toOutcome membawa konteks pemakaian sebelumnya untuk ALREADY_USED', () {
      final result = ScanResult.fromJson(
        {
          'status': 'already_used',
          'ticket_code': 'TKT-2026-001244',
          'visitor_name': 'Nadia Kusuma',
          'visitor_count': 2,
          'used_at': '2026-10-07T05:30:00.000Z',
          'used_at_checkpoint': 'Gate B',
        },
        mode: ScanMode.checkIn,
        scannedAt: DateTime(2026, 10, 7, 12, 30),
      );

      final outcome = result.toOutcome(gate: 'Gate 1');

      expect(outcome.status, TicketStatus.alreadyUsed);
      expect(outcome.code, 'TKT-2026-001244');
      expect(outcome.visitor, 'Nadia Kusuma');
      expect(outcome.tickets, 2);
      expect(outcome.gate, 'Gate B');
      expect(outcome.previousUseAt, isNotNull);
      expect(outcome.previousUseGate, 'Gate B');
      expect(outcome.simulated, isFalse);
    });

    test('toOutcome memakai gate petugas saat payload tidak menyebut gate', () {
      final result = ScanResult.fromJson(
        const {'status': 'valid', 'ticket_code': 'TKT-1'},
        mode: ScanMode.check,
      );

      final outcome = result.toOutcome(gate: 'Gate 7');

      expect(outcome.gate, 'Gate 7');
      expect(outcome.previousUseAt, isNull);
      expect(outcome.previousUseGate, isNull);
    });
  });
}
