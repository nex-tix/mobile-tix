// File: scanner_screen_test.dart
// Widget test ScannerScreen ↔ ScannerCubit (mode, hasil scan, antrean offline).

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mobile_tix/core/connectivity/connectivity_monitor.dart';
import 'package:mobile_tix/core/connectivity/demo_connectivity.dart';
import 'package:mobile_tix/core/constants/app_icons.dart';
import 'package:mobile_tix/core/constants/ticket_status.dart';
import 'package:mobile_tix/core/data/dao/offline_queue_dao.dart';
import 'package:mobile_tix/core/error/api_failure.dart';
import 'package:mobile_tix/core/ui/widgets/app_snackbar.dart';
import 'package:mobile_tix/features/auth/logic/session_state.dart';
import 'package:mobile_tix/features/checkpoint/data/models/checkpoint.dart';
import 'package:mobile_tix/features/scanner/bloc/scanner_cubit.dart';
import 'package:mobile_tix/features/scanner/data/models/scan_result.dart';
import 'package:mobile_tix/features/scanner/data/repositories/ticket_repository.dart';
import 'package:mobile_tix/features/scanner/presentation/screens/scanner_screen.dart';
import 'package:mobile_tix/features/scanner/presentation/widgets/scanner_viewfinder.dart';
import 'package:provider/provider.dart';

class _FakeTicketRepository implements TicketRepository {
  final List<String> calls = <String>[];

  /// Verdict yang dijawab server.
  TicketStatus status = TicketStatus.alreadyUsed;

  /// Bila diisi, panggilan melempar error ini.
  ApiFailure? failure;

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
    int? actualVisitorCount,
  }) {
    calls.add('checkIn|$checkpointId|$ticketCode');
    return _respond(ticketCode, ScanMode.checkIn);
  }

  Future<ScanResult> _respond(String ticketCode, ScanMode mode) async {
    final error = failure;
    if (error != null) throw error;

    return ScanResult(
      status: status,
      ticketCode: ticketCode,
      mode: mode,
      scannedAt: DateTime(2026, 10, 8, 9, 30),
      visitorName: 'Rangga Prasetyo',
      visitorCount: 1,
      category: 'Individu',
      usedAtCheckpoint: 'Gate A',
    );
  }
}

/// Selalu online.
///
/// Jalur offline sengaja tidak diuji di level widget: menyimpannya butuh
/// penulisan Hive nyata, dan itu diuji di `scanner_cubit_test.dart` yang berjalan
/// tanpa zona waktu palsu.
class _FakeConnectivity implements ConnectivityMonitor {
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  @override
  bool get isOnline => true;

  @override
  Stream<bool> get onlineChanges => _controller.stream;

  Future<void> dispose() => _controller.close();
}

/// Beberapa pump pendek — viewfinder & spinner beranimasi terus, jadi
/// `pumpAndSettle` tidak akan pernah selesai di layar ini.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 300));
}

/// Tutup notifikasi atas dan tunggu animasinya selesai.
///
/// Wajib dipanggil di akhir test yang memunculkan notifikasi: selain menyisakan
/// Timer auto-dismiss yang membuat test gagal, entri overlay yang tertinggal
/// akan dibuang oleh test berikutnya saat overlay-nya sudah tidak ada.
Future<void> flushSnackbar(WidgetTester tester) async {
  AppSnackbar.dismiss();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  late OfflineQueueDAO queueDao;
  late _FakeTicketRepository repository;
  late _FakeConnectivity connectivity;
  late SessionState session;
  late ScannerCubit cubit;

  setUpAll(() {
    Hive.init(Directory.systemTemp.createTempSync('scanner_screen_test').path);
    OfflineQueueDAO.registerAdapters();
  });

  setUp(() async {
    queueDao = OfflineQueueDAO();
    await queueDao.initialize();
    await queueDao.clear();

    repository = _FakeTicketRepository();
    connectivity = _FakeConnectivity();
    session = SessionState()
      ..selectCheckpoint(
        const Checkpoint(
          id: 'cp-01',
          gate: 'Gate 1',
          name: 'Pintu Utama',
          note: 'Shift pagi',
        ),
      );
  });

  tearDown(() async {
    await cubit.close();
    await connectivity.dispose();
  });

  ScannerCubit buildCubit() {
    cubit = ScannerCubit(
      repository: repository,
      queueDao: queueDao,
      connectivity: connectivity,
    );
    return cubit;
  }

  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionState>.value(value: session),
        ChangeNotifierProvider<DemoConnectivity>(
          create: (_) => DemoConnectivity(),
        ),
        BlocProvider<ScannerCubit>.value(value: buildCubit()),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('memindai menampilkan verdict dari server', (tester) async {
    await tester.pumpWidget(wrap(const ScannerScreen()));
    await settle(tester);

    // Layar memakai checkpoint aktif petugas sebagai checkpointId.
    await tester.tap(find.byType(ScannerViewfinder));
    await settle(tester);

    expect(repository.calls.single, 'checkIn|cp-01|TKT-2026-001245');
    expect(find.text('ALREADY USED'), findsOneWidget);
  });

  testWidgets('mode Cek memakai endpoint cek, bukan check-in', (tester) async {
    await tester.pumpWidget(wrap(const ScannerScreen()));
    await settle(tester);

    await tester.tap(find.text('Check'));
    await settle(tester);
    expect(cubit.state.mode, ScanMode.check);

    await tester.tap(find.byType(ScannerViewfinder));
    await settle(tester);

    expect(repository.calls.single, 'check|cp-01|TKT-2026-001245');
  });

  testWidgets('tiket yang tertahan saat offline tampil sebagai antrean', (
    tester,
  ) async {
    // Antrean diisi lewat runAsync: Hive menulis ke disk, dan I/O nyata tidak
    // akan pernah selesai di dalam zona waktu palsu milik testWidgets.
    await tester.runAsync(
      () => queueDao.enqueue(ticketCode: 'TKT-TERTAHAN', checkpointId: 'cp-01'),
    );

    await tester.pumpWidget(wrap(const ScannerScreen()));
    await settle(tester);

    expect(find.text('1 tiket menunggu dikirim ke server'), findsOneWidget);
  });

  testWidgets('kode manual juga dikirim ke server lewat cubit', (tester) async {
    await tester.pumpWidget(wrap(const ScannerScreen()));
    await settle(tester);

    await tester.tap(find.text('Enter code manually'));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'TKT-MANUAL-1');
    await tester.tap(find.byIcon(AppIcons.arrowForward));
    await settle(tester);

    expect(repository.calls.single, 'checkIn|cp-01|TKT-MANUAL-1');
    expect(find.text('ALREADY USED'), findsOneWidget);
  });

  testWidgets('kegagalan ditampilkan kepada petugas, tidak didiamkan', (
    tester,
  ) async {
    repository.failure = const ApiFailure(
      kind: ApiFailureKind.server,
      message: 'Gate tidak aktif',
      statusCode: 500,
    );

    await tester.pumpWidget(wrap(const ScannerScreen()));
    await settle(tester);

    await tester.tap(find.byType(ScannerViewfinder));
    await settle(tester);

    expect(find.text('Gate tidak aktif'), findsOneWidget);

    await flushSnackbar(tester);
  });
}
