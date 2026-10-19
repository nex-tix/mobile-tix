// File: dashboard_pending_queue_test.dart
// Widget test antrean offline pada DashboardScreen (list tiket pending & tombol sinkronisasi manual).

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mobile_tix/core/connectivity/demo_connectivity.dart';
import 'package:mobile_tix/core/constants/ticket_status.dart';
import 'package:mobile_tix/core/data/dao/offline_queue_dao.dart';
import 'package:mobile_tix/core/data/repositories/dashboard_repository.dart';
import 'package:mobile_tix/core/ui/widgets/app_snackbar.dart';
import 'package:mobile_tix/features/auth/logic/session_state.dart';
import 'package:mobile_tix/features/dashboard/bloc/dashboard_cubit.dart';
import 'package:mobile_tix/features/dashboard/data/models/dashboard_stats.dart';
import 'package:mobile_tix/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:mobile_tix/features/history/data/models/scan_record_page.dart';
import 'package:mobile_tix/features/scanner/bloc/scanner_cubit.dart';
import 'package:mobile_tix/features/scanner/data/models/scan_result.dart';
import 'package:mobile_tix/features/scanner/data/repositories/ticket_repository.dart';
import 'package:provider/provider.dart';

class _FakeDashboardRepository implements DashboardRepository {
  int refreshCallCount = 0;

  @override
  Future<DashboardStats> getSummary({
    StatsPeriod period = StatsPeriod.today,
  }) async {
    refreshCallCount++;
    return DashboardStats(
      period: period,
      totalVisitors: 50,
      validTickets: 45,
      rejectedTickets: 5,
    );
  }

  @override
  Future<ScanRecordPage> getTicketHistory({
    int page = 1,
    int pageSize = 10,
    String? checkpoint,
    String? status,
    String? date,
  }) => throw UnimplementedError();
}

class _FakeTicketRepository implements TicketRepository {
  final List<String> syncedTickets = <String>[];

  @override
  Future<ScanResult> checkTicket({
    required String ticketCode,
    required String checkpointId,
  }) async => throw UnimplementedError();

  @override
  Future<ScanResult> validateAndCheckIn({
    required String ticketCode,
    required String checkpointId,
    int? actualVisitorCount,
  }) async {
    syncedTickets.add(ticketCode);
    return ScanResult(
      ticketCode: ticketCode,
      status: TicketStatus.valid,
      mode: ScanMode.checkIn,
      scannedAt: DateTime.now(),
      visitorCount: actualVisitorCount ?? 1,
    );
  }
}

class _TestConnectivity with ChangeNotifier implements DemoConnectivity {
  _TestConnectivity({bool initialOnline = true}) : _online = initialOnline;

  bool _online;

  @override
  bool get online => _online;

  @override
  bool get offline => !_online;

  @override
  bool get isChecking => false;

  @override
  bool get isOnline => _online;

  final _changes = StreamController<bool>.broadcast();
  final _lostStream = StreamController<void>.broadcast();
  final _restoredStream = StreamController<void>.broadcast();

  @override
  Stream<bool> get onlineChanges => _changes.stream;

  @override
  Stream<void> get onConnectionLost => _lostStream.stream;

  @override
  Stream<void> get onConnectionRestored => _restoredStream.stream;

  void setOnline(bool value) {
    _online = value;
    _changes.add(value);
    notifyListeners();
  }

  @override
  Future<bool> checkConnection() async => _online;

  @override
  void toggle() {
    setOnline(!_online);
  }
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> flushSnackbar(WidgetTester tester) async {
  AppSnackbar.dismiss();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  late OfflineQueueDAO queueDao;
  late _FakeDashboardRepository dashboardRepository;
  late _FakeTicketRepository ticketRepository;
  late _TestConnectivity connectivity;
  late DashboardCubit dashboardCubit;
  late ScannerCubit scannerCubit;

  setUpAll(() {
    Hive.init(
      Directory.systemTemp.createTempSync('dashboard_pending_test').path,
    );
    OfflineQueueDAO.registerAdapters();
  });

  setUp(() async {
    queueDao = OfflineQueueDAO();
    await queueDao.initialize();
    await queueDao.clear();

    dashboardRepository = _FakeDashboardRepository();
    ticketRepository = _FakeTicketRepository();
    connectivity = _TestConnectivity();

    dashboardCubit = DashboardCubit(repository: dashboardRepository);
    scannerCubit = ScannerCubit(
      repository: ticketRepository,
      connectivity: connectivity,
      queueDao: queueDao,
    );
  });

  tearDown(() async {
    AppSnackbar.dismiss();
    await queueDao.clear();
    await dashboardCubit.close();
    await scannerCubit.close();
  });

  Widget wrap() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionState>(create: (_) => SessionState()),
        ChangeNotifierProvider<DemoConnectivity>.value(value: connectivity),
        BlocProvider<DashboardCubit>.value(value: dashboardCubit),
        BlocProvider<ScannerCubit>.value(value: scannerCubit),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    );
  }

  testWidgets('tidak menampilkan antrean pending jika antrean kosong', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await settle(tester);

    expect(find.text('Menunggu Dikirim'), findsNothing);
    expect(find.text('Kirim ke Server'), findsNothing);
  });

  testWidgets(
    'menampilkan antrean pending dan data tiket dengan riil pengunjung ketika ada item',
    (tester) async {
      await tester.runAsync(() async {
        await queueDao.enqueue(
          ticketCode: 'TKT-GRP-888',
          checkpointId: 'cp-01',
          mode: 'checkIn',
          actualVisitorCount: 8,
        );
      });

      // Trigger update pendingSync di scannerCubit
      scannerCubit.setMode(ScanMode.check);

      await tester.pumpWidget(wrap());
      await settle(tester);

      expect(find.text('Menunggu Dikirim'), findsOneWidget);
      expect(find.text('TKT-GRP-888'), findsOneWidget);
      expect(find.textContaining('8 orang hadir'), findsOneWidget);
      expect(find.text('Kirim ke Server'), findsOneWidget);

      await flushSnackbar(tester);
    },
  );

  testWidgets(
    'tombol kirim ke server menampilkan snackbar peringatan saat offline',
    (tester) async {
      await tester.runAsync(() async {
        await queueDao.enqueue(
          ticketCode: 'TKT-OFFLINE-01',
          checkpointId: 'cp-01',
          mode: 'checkIn',
          actualVisitorCount: 4,
        );
      });

      connectivity.setOnline(false);
      scannerCubit.setMode(ScanMode.check);

      await tester.pumpWidget(wrap());
      await settle(tester);

      final sendBtn = find.text('Kirim ke Server');
      expect(sendBtn, findsOneWidget);
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pump();

      expect(
        find.textContaining('Tidak ada koneksi internet'),
        findsOneWidget,
      );

      await flushSnackbar(tester);
    },
  );

  testWidgets(
    'tombol kirim ke server memproses sinkronisasi saat online dan memicu reload metrik',
    (tester) async {
      await tester.runAsync(() async {
        await queueDao.enqueue(
          ticketCode: 'TKT-SYNC-01',
          checkpointId: 'cp-01',
          mode: 'checkIn',
          actualVisitorCount: 6,
        );
      });

      // Update state pendingSync di scannerCubit
      scannerCubit.setMode(ScanMode.check);

      await tester.pumpWidget(wrap());
      await settle(tester);

      final initialRefreshCount = dashboardRepository.refreshCallCount;

      final sendBtn = find.text('Kirim ke Server');
      expect(sendBtn, findsOneWidget);
      await tester.ensureVisible(sendBtn);

      await tester.runAsync(() async {
        await tester.tap(sendBtn);
        await Future.delayed(const Duration(milliseconds: 300));
      });

      await tester.pump();
      await settle(tester);

      expect(ticketRepository.syncedTickets.contains('TKT-SYNC-01'), isTrue);
      expect(
        dashboardRepository.refreshCallCount,
        greaterThan(initialRefreshCount),
      );

      await flushSnackbar(tester);
    },
  );
}
