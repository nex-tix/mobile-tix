// File: ticket_repository_test.dart
// Unit test TicketRepository — kontrak enam status dari dua endpoint validasi.

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/core/constants/ticket_status.dart';
import 'package:mobile_tix/core/error/api_failure.dart';
import 'package:mobile_tix/core/services/api_service.dart';
import 'package:mobile_tix/core/services/encryption_service.dart';
import 'package:mobile_tix/features/scanner/data/repositories/ticket_repository.dart';

void main() {
  group('TicketRepository (mock API)', () {
    late TicketRepository repository;

    setUpAll(() {
      EncryptionService.initialize();
    });

    setUp(() {
      // Mock diaktifkan eksplisit (EnvConfig.useMockApi bawaannya false).
      repository = TicketRepositoryImpl(ApiService(useMockApi: true));
    });

    test('mode Cek memetakan keenam verdict', () async {
      Future<TicketStatus> statusFor(String code) async {
        final result = await repository.checkTicket(
          ticketCode: code,
          checkpointId: 'cp-01',
        );
        return result.status;
      }

      expect(await statusFor('VALID-2026-001'), TicketStatus.valid);
      expect(await statusFor('USED-2026-001'), TicketStatus.alreadyUsed);
      expect(await statusFor('EXPIRED-2026-001'), TicketStatus.expired);
      expect(await statusFor('NOTYET-2026-001'), TicketStatus.notYetValid);
      expect(await statusFor('CANCEL-2026-001'), TicketStatus.cancelled);
      expect(await statusFor('TIDAK-DIKENAL'), TicketStatus.notFound);
    });

    test('mode Check-in memetakan keenam verdict', () async {
      Future<TicketStatus> statusFor(String code) async {
        final result = await repository.validateAndCheckIn(
          ticketCode: code,
          checkpointId: 'cp-01',
        );
        return result.status;
      }

      expect(await statusFor('VALID-2026-001'), TicketStatus.valid);
      expect(await statusFor('USED-2026-001'), TicketStatus.alreadyUsed);
      expect(await statusFor('EXPIRED-2026-001'), TicketStatus.expired);
      expect(await statusFor('NOTYET-2026-001'), TicketStatus.notYetValid);
      expect(await statusFor('CANCEL-2026-001'), TicketStatus.cancelled);
      expect(await statusFor('TIDAK-DIKENAL'), TicketStatus.notFound);
    });

    test('check-in tiket valid membawa gate petugas dan detail pemegang', () async {
      final result = await repository.validateAndCheckIn(
        ticketCode: 'VALID-2026-002',
        checkpointId: 'Gate 3',
      );

      expect(result.status, TicketStatus.valid);
      expect(result.isCheckedIn, isTrue);
      expect(result.usedAtCheckpoint, 'Gate 3');
      expect(result.visitorName, isNotNull);
      expect(result.visitorCount, greaterThan(0));
      expect(result.usedAt, isNotNull);
    });

    test('mode Cek tidak menulis tiket (usedAtCheckpoint tidak diisi)', () async {
      final result = await repository.checkTicket(
        ticketCode: 'VALID-2026-003',
        checkpointId: 'Gate 3',
      );

      expect(result.status, TicketStatus.valid);
      expect(result.isCheckedIn, isFalse);
      expect(result.usedAtCheckpoint, isNull);
    });

    test('kode demo TKT- mengikuti aturan digit terakhir prototype', () async {
      final used = await repository.validateAndCheckIn(
        ticketCode: 'TKT-2026-001244',
        checkpointId: 'cp-01',
      );
      final unknown = await repository.validateAndCheckIn(
        ticketCode: 'TKT-2026-001240',
        checkpointId: 'cp-01',
      );

      expect(used.status, TicketStatus.alreadyUsed);
      expect(used.usedAt, isNotNull);
      expect(used.usedAtCheckpoint, isNotNull);
      expect(unknown.status, TicketStatus.notFound);
    });

    test('kegagalan server menjadi ApiFailure, bukan verdict', () async {
      await expectLater(
        repository.checkTicket(
          ticketCode: 'ERR-2026-001',
          checkpointId: 'cp-01',
        ),
        throwsA(
          isA<ApiFailure>().having(
            (failure) => failure.kind,
            'kind',
            ApiFailureKind.server,
          ),
        ),
      );
    });

    test('kode tiket kosong ditolak sebelum request dikirim', () async {
      await expectLater(
        repository.checkTicket(ticketCode: '   ', checkpointId: 'cp-01'),
        throwsA(isA<ApiFailure>()),
      );
    });

    test('checkpoint kosong ditolak sebelum request dikirim', () async {
      await expectLater(
        repository.validateAndCheckIn(ticketCode: 'VALID-1', checkpointId: ''),
        throwsA(isA<ApiFailure>()),
      );
    });
  });
}
