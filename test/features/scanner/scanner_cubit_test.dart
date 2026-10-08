// File: scanner_cubit_test.dart
// Unit test ScannerCubit: dua mode scan, antrean offline, dan auto-sync.

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mobile_tix/core/connectivity/connectivity_monitor.dart';
import 'package:mobile_tix/core/constants/ticket_status.dart';
import 'package:mobile_tix/core/data/dao/offline_queue_dao.dart';
import 'package:mobile_tix/core/error/api_failure.dart';
import 'package:mobile_tix/features/scanner/bloc/scanner_cubit.dart';
import 'package:mobile_tix/features/scanner/bloc/scanner_state.dart';
import 'package:mobile_tix/features/scanner/data/models/scan_result.dart';
import 'package:mobile_tix/features/scanner/data/repositories/ticket_repository.dart';

/// Repository palsu: mencatat pemanggilan dan menjawab lewat [handler].
class _FakeTicketRepository implements TicketRepository {
  final List<String> calls = <String>[];

  /// Jawaban per pemanggilan. Melempar [ApiFailure] bila handler melemparnya.
  Future<ScanResult> Function(String ticketCode, ScanMode mode)? handler;

  @override
  Future<ScanResult> checkTicket({
    required String ticketCode,
    required String checkpointId,
  }) {
    calls.add('check|$checkpointId|$ticketCode');
    return _respond(ticketCode, ScanMode.check);
  }

  @override
  Future<ScanResult> validateAndCheckIn({
    required String ticketCode,
    required String checkpointId,
  }) {
    calls.add('checkIn|$checkpointId|$ticketCode');
    return _respond(ticketCode, ScanMode.checkIn);
  }

  Future<ScanResult> _respond(String ticketCode, ScanMode mode) async {
    final current = handler;
    if (current != null) return current(ticketCode, mode);
    return ScanResult(
      status: TicketStatus.valid,
      ticketCode: ticketCode,
      mode: mode,
      scannedAt: DateTime.now(),
      visitorName: 'Rangga Prasetyo',
    );
  }
}

/// Monitor koneksi palsu yang bisa dipicu dari test.
class _FakeConnectivity implements ConnectivityMonitor {
  _FakeConnectivity({this._online = true});

  bool _online;
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  @override
  bool get isOnline => _online;

  @override
  Stream<bool> get onlineChanges => _controller.stream;

  void setOnline(bool value) {
    _online = value;
    _controller.add(value);
  }

  Future<void> dispose() => _controller.close();
}

ScanResult _result(String code, ScanMode mode) => ScanResult(
  status: TicketStatus.valid,
  ticketCode: code,
  mode: mode,
  scannedAt: DateTime.now(),
);

/// Tunggu sampai [condition] benar — menggantikan sleep tetap yang rapuh.
Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Kondisi tidak terpenuhi dalam 5 detik');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  group('ScannerCubit', () {
    late OfflineQueueDAO queueDao;
    late _FakeTicketRepository repository;

    setUpAll(() {
      Hive.init(
        Directory.systemTemp.createTempSync('scanner_cubit_test').path,
      );
      OfflineQueueDAO.registerAdapters();
    });

    setUp(() async {
      queueDao = OfflineQueueDAO();
      await queueDao.initialize();
      await queueDao.clear();
      repository = _FakeTicketRepository();
    });

    group('mode & state awal', () {
      test('mulai dari idle dengan mode check-in', () async {
        final cubit = ScannerCubit(
          repository: repository,
          queueDao: queueDao,
        );
        addTearDown(cubit.close);

        expect(cubit.state, isA<ScannerIdle>());
        expect(cubit.state.mode, ScanMode.checkIn);
        expect(cubit.state.pendingSync, 0);
        expect(cubit.pendingSyncCount, 0);
      });

      test('setMode mengganti endpoint yang dipakai', () async {
        final cubit = ScannerCubit(
          repository: repository,
          queueDao: queueDao,
        );
        addTearDown(cubit.close);

        cubit.setMode(ScanMode.check);
        expect(cubit.mode, ScanMode.check);

        await cubit.scanTicket(ticketCode: 'TKT-1', checkpointId: 'cp-01');

        expect(repository.calls, equals(['check|cp-01|TKT-1']));
      });

      test('setMode tidak mengubah apa pun bila mode sama', () async {
        final cubit = ScannerCubit(
          repository: repository,
          queueDao: queueDao,
        );
        addTearDown(cubit.close);

        final before = cubit.state;
        cubit.setMode(ScanMode.checkIn);
        expect(identical(cubit.state, before), isTrue);
      });
    });

    group('scan online', () {
      test('check-in memanggil validateAndCheckIn dan emit hasilnya', () async {
        final cubit = ScannerCubit(
          repository: repository,
          queueDao: queueDao,
        );
        addTearDown(cubit.close);

        await cubit.scanTicket(
          ticketCode: 'TKT-2026-001245',
          checkpointId: 'cp-09',
        );

        expect(repository.calls, equals(['checkIn|cp-09|TKT-2026-001245']));
        final state = cubit.state;
        expect(state, isA<ScannerSuccess>());
        expect((state as ScannerSuccess).result.ticketCode, 'TKT-2026-001245');
        expect(state.pendingSync, 0);
      });

      test('verdict non-valid tetap sukses sebagai sebuah respons', () async {
        repository.handler = (code, mode) async => ScanResult(
          status: TicketStatus.alreadyUsed,
          ticketCode: code,
          mode: mode,
          scannedAt: DateTime.now(),
        );

        final cubit = ScannerCubit(
          repository: repository,
          queueDao: queueDao,
        );
        addTearDown(cubit.close);

        await cubit.scanTicket(ticketCode: 'USED-1', checkpointId: 'cp-01');

        expect(cubit.state, isA<ScannerSuccess>());
        expect(
          (cubit.state as ScannerSuccess).result.status,
          TicketStatus.alreadyUsed,
        );
        expect(queueDao.hasItems, isFalse);
      });

      test('kode kosong ditolak tanpa memanggil repository', () async {
        final cubit = ScannerCubit(
          repository: repository,
          queueDao: queueDao,
        );
        addTearDown(cubit.close);

        await cubit.scanTicket(ticketCode: '   ', checkpointId: 'cp-01');

        expect(cubit.state, isA<ScannerError>());
        expect(repository.calls, isEmpty);
      });

      test('acknowledgeResult mengembalikan layar ke idle', () async {
        final cubit = ScannerCubit(
          repository: repository,
          queueDao: queueDao,
        );
        addTearDown(cubit.close);

        await cubit.scanTicket(ticketCode: 'TKT-1', checkpointId: 'cp-01');
        expect(cubit.state, isA<ScannerSuccess>());

        cubit.acknowledgeResult();

        expect(cubit.state, isA<ScannerIdle>());
        expect(cubit.mode, ScanMode.checkIn);
      });
    });

    group('kegagalan', () {
      test('kegagalan koneksi → scan masuk antrean offline', () async {
        repository.handler = (code, mode) async =>
            throw const ApiFailure(
              kind: ApiFailureKind.network,
              message: 'Tidak ada koneksi ke server',
            );

        final cubit = ScannerCubit(
          repository: repository,
          queueDao: queueDao,
        );
        addTearDown(cubit.close);

        await cubit.scanTicket(ticketCode: 'TKT-OFF-1', checkpointId: 'cp-07');

        expect(cubit.state, isA<ScannerQueued>());
        expect((cubit.state as ScannerQueued).ticketCode, 'TKT-OFF-1');
        expect(cubit.state.pendingSync, 1);

        final queued = queueDao.getAll();
        expect(queued.length, 1);
        expect(queued.first.ticketCode, 'TKT-OFF-1');
        expect(queued.first.checkpointId, 'cp-07');
        expect(queued.first.mode, 'checkIn');
      });

      test('sudah tahu offline → tidak ada request yang dicoba', () async {
        final connectivity = _FakeConnectivity(online: false);
        addTearDown(connectivity.dispose);

        final cubit = ScannerCubit(
          repository: repository,
          queueDao: queueDao,
          connectivity: connectivity,
        );
        addTearDown(cubit.close);

        await cubit.scanTicket(ticketCode: 'TKT-OFF-2', checkpointId: 'cp-01');

        expect(repository.calls, isEmpty);
        expect(cubit.state, isA<ScannerQueued>());
        expect(queueDao.size, 1);
      });

      test('scan tiket yang sudah ada di antrean offline mencegah duplikasi queue', () async {
        final connectivity = _FakeConnectivity(online: false);
        addTearDown(connectivity.dispose);

        final cubit = ScannerCubit(
          repository: repository,
          queueDao: queueDao,
          connectivity: connectivity,
        );
        addTearDown(cubit.close);

        // Scan pertama saat offline -> masuk antrean
        await cubit.scanTicket(ticketCode: 'TKT-DUP', checkpointId: 'cp-01');
        expect(cubit.state, isA<ScannerQueued>());
        expect(queueDao.size, 1);

        // Scan kedua dengan tiket yang sama -> tetap queued, antrean tidak bertambah
        await cubit.scanTicket(ticketCode: 'TKT-DUP', checkpointId: 'cp-01');
        expect(cubit.state, isA<ScannerQueued>());
        expect(queueDao.size, 1);
        expect(repository.calls, isEmpty);
      });

      test('timeout TIDAK diantrekan (request bisa saja sudah diproses)', () async {
        repository.handler = (code, mode) async =>
            throw const ApiFailure(
              kind: ApiFailureKind.timeout,
              message: 'Server tidak merespons, coba lagi',
            );

        final cubit = ScannerCubit(
          repository: repository,
          queueDao: queueDao,
        );
        addTearDown(cubit.close);

        await cubit.scanTicket(ticketCode: 'TKT-TIMEOUT', checkpointId: 'cp-01');

        expect(cubit.state, isA<ScannerError>());
        expect((cubit.state as ScannerError).kind, ScanFailureKind.timeout);
        expect(queueDao.hasItems, isFalse);
      });

      test('penolakan server dilaporkan sebagai error, bukan antrean', () async {
        repository.handler = (code, mode) async =>
            throw const ApiFailure(
              kind: ApiFailureKind.server,
              message: 'Gate tidak aktif',
              statusCode: 500,
            );

        final cubit = ScannerCubit(
          repository: repository,
          queueDao: queueDao,
        );
        addTearDown(cubit.close);

        await cubit.scanTicket(ticketCode: 'TKT-ERR', checkpointId: 'cp-01');

        final state = cubit.state as ScannerError;
        expect(state.kind, ScanFailureKind.server);
        expect(state.message, 'Gate tidak aktif');
        expect(queueDao.hasItems, isFalse);
      });

      test('401 dilaporkan sebagai unauthorized', () async {
        repository.handler = (code, mode) async =>
            throw const ApiFailure(
              kind: ApiFailureKind.unauthorized,
              message: 'Sesi berakhir, silakan masuk ulang',
              statusCode: 401,
            );

        final cubit = ScannerCubit(
          repository: repository,
          queueDao: queueDao,
        );
        addTearDown(cubit.close);

        await cubit.scanTicket(ticketCode: 'TKT-401', checkpointId: 'cp-01');

        expect(
          (cubit.state as ScannerError).kind,
          ScanFailureKind.unauthorized,
        );
      });

      test('exception tak terduga tetap menghasilkan ScannerError', () async {
        repository.handler = (code, mode) async =>
            throw StateError('boom');

        final cubit = ScannerCubit(
          repository: repository,
          queueDao: queueDao,
        );
        addTearDown(cubit.close);

        await cubit.scanTicket(ticketCode: 'TKT-BOOM', checkpointId: 'cp-01');

        expect((cubit.state as ScannerError).kind, ScanFailureKind.unknown);
      });

      test('scan kedua diabaikan selama scan pertama berjalan', () async {
        final gate = Completer<void>();
        repository.handler = (code, mode) async {
          await gate.future;
          return _result(code, mode);
        };

        final cubit = ScannerCubit(
          repository: repository,
          queueDao: queueDao,
        );
        addTearDown(cubit.close);

        final first = cubit.scanTicket(ticketCode: 'TKT-A', checkpointId: 'cp-01');
        expect(cubit.state, isA<ScannerProcessing>());

        await cubit.scanTicket(ticketCode: 'TKT-B', checkpointId: 'cp-01');
        expect(repository.calls.length, 1);

        gate.complete();
        await first;

        expect(repository.calls, equals(['checkIn|cp-01|TKT-A']));
        expect(cubit.state, isA<ScannerSuccess>());
      });
    });

    group('processOfflineQueue', () {
      test('mengirim antrean secara FIFO lalu mengosongkannya', () async {
        await queueDao.enqueue(
          ticketCode: 'TKT-OLD',
          checkpointId: 'cp-01',
          mode: 'checkIn',
        );
        await queueDao.enqueue(
          ticketCode: 'TKT-NEW',
          checkpointId: 'cp-02',
          mode: 'check',
        );

        final cubit = ScannerCubit(
          repository: repository,
          queueDao: queueDao,
        );
        addTearDown(cubit.close);

        final synced = await cubit.processOfflineQueue();

        expect(synced, 2);
        expect(queueDao.hasItems, isFalse);
        expect(
          repository.calls,
          equals(['checkIn|cp-01|TKT-OLD', 'check|cp-02|TKT-NEW']),
        );
      });

      test('berhenti di item yang gagal karena koneksi, sisanya tetap antre',
          () async {
        await queueDao.enqueue(
          ticketCode: 'TKT-A',
          checkpointId: 'cp-01',
          mode: 'checkIn',
        );
        await queueDao.enqueue(
          ticketCode: 'TKT-B',
          checkpointId: 'cp-01',
          mode: 'checkIn',
        );
        await queueDao.enqueue(
          ticketCode: 'TKT-C',
          checkpointId: 'cp-01',
          mode: 'checkIn',
        );

        repository.handler = (code, mode) async {
          if (code == 'TKT-B') {
            throw const ApiFailure(
              kind: ApiFailureKind.network,
              message: 'koneksi putus lagi',
            );
          }
          return _result(code, mode);
        };

        final cubit = ScannerCubit(
          repository: repository,
          queueDao: queueDao,
        );
        addTearDown(cubit.close);

        final synced = await cubit.processOfflineQueue();

        expect(synced, 1);
        expect(repository.calls, equals(['checkIn|cp-01|TKT-A', 'checkIn|cp-01|TKT-B']));
        expect(
          queueDao.getAll().map((scan) => scan.ticketCode).toList(),
          equals(['TKT-B', 'TKT-C']),
        );
        // Item yang gagal karena koneksi bukan salah tiket → retry tetap 0.
        expect(queueDao.getAll().first.retryCount, 0);
      });

      test('item yang ditolak server tetap antre dengan retry bertambah',
          () async {
        await queueDao.enqueue(
          ticketCode: 'TKT-REJECT',
          checkpointId: 'cp-01',
          mode: 'checkIn',
        );
        await queueDao.enqueue(
          ticketCode: 'TKT-OK',
          checkpointId: 'cp-01',
          mode: 'checkIn',
        );

        repository.handler = (code, mode) async {
          if (code == 'TKT-REJECT') {
            throw const ApiFailure(
              kind: ApiFailureKind.server,
              message: 'tiket rusak',
              statusCode: 422,
            );
          }
          return _result(code, mode);
        };

        final cubit = ScannerCubit(
          repository: repository,
          queueDao: queueDao,
        );
        addTearDown(cubit.close);

        final synced = await cubit.processOfflineQueue();

        expect(synced, 1);
        final remaining = queueDao.getAll();
        expect(remaining.length, 1);
        expect(remaining.first.ticketCode, 'TKT-REJECT');
        expect(remaining.first.retryCount, 1);
      });

      test('sync tidak dijalankan saat perangkat masih offline', () async {
        final connectivity = _FakeConnectivity(online: false);
        addTearDown(connectivity.dispose);

        await queueDao.enqueue(
          ticketCode: 'TKT-OFF',
          checkpointId: 'cp-01',
          mode: 'checkIn',
        );

        final cubit = ScannerCubit(
          repository: repository,
          queueDao: queueDao,
          connectivity: connectivity,
        );
        addTearDown(cubit.close);

        final synced = await cubit.processOfflineQueue();

        expect(synced, 0);
        expect(repository.calls, isEmpty);
        expect(queueDao.size, 1);
      });
    });

    group('auto-sync saat koneksi pulih', () {
      test('antrean terkirim sendiri begitu koneksi kembali', () async {
        final connectivity = _FakeConnectivity(online: false);
        addTearDown(connectivity.dispose);

        final cubit = ScannerCubit(
          repository: repository,
          queueDao: queueDao,
          connectivity: connectivity,
        );
        addTearDown(cubit.close);

        await cubit.scanTicket(ticketCode: 'TKT-OFFLINE', checkpointId: 'cp-05');
        expect(cubit.state, isA<ScannerQueued>());
        expect(queueDao.size, 1);

        connectivity.setOnline(true);

        await _waitFor(() => !queueDao.hasItems);

        expect(repository.calls, equals(['checkIn|cp-05|TKT-OFFLINE']));
        expect(cubit.pendingSyncCount, 0);
      });

      test('koneksi putus tidak memicu sync', () async {
        final connectivity = _FakeConnectivity();
        addTearDown(connectivity.dispose);

        await queueDao.enqueue(
          ticketCode: 'TKT-X',
          checkpointId: 'cp-01',
          mode: 'checkIn',
        );

        final cubit = ScannerCubit(
          repository: repository,
          queueDao: queueDao,
          connectivity: connectivity,
        );
        addTearDown(cubit.close);

        connectivity.setOnline(false);
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(repository.calls, isEmpty);
        expect(queueDao.size, 1);
      });
    });
  });
}
