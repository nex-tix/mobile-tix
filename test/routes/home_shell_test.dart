// File: home_shell_test.dart
// Smoke test wiring: ketiga layar hidup bersama di dalam satu shell, memakai
// repository nyata di atas API mock (tanpa fake) — inilah yang memverifikasi
// provider di app.dart benar-benar bisa menyuplai ketiga cubit sekaligus.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mobile_tix/core/connectivity/demo_connectivity.dart';
import 'package:mobile_tix/core/data/dao/offline_queue_dao.dart';
import 'package:mobile_tix/core/data/repositories/dashboard_repository.dart';
import 'package:mobile_tix/core/services/api_service.dart';
import 'package:mobile_tix/core/services/encryption_service.dart';
import 'package:mobile_tix/features/auth/logic/session_state.dart';
import 'package:mobile_tix/features/checkpoint/data/models/checkpoint.dart';
import 'package:mobile_tix/features/dashboard/bloc/dashboard_cubit.dart';
import 'package:mobile_tix/features/history/bloc/history_cubit.dart';
import 'package:mobile_tix/features/scanner/bloc/scanner_cubit.dart';
import 'package:mobile_tix/features/scanner/data/repositories/ticket_repository.dart';
import 'package:mobile_tix/routes/home_shell.dart';
import 'package:mobile_tix/routes/shell_controller.dart';
import 'package:provider/provider.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pump(const Duration(milliseconds: 20));
}

void main() {
  late OfflineQueueDAO queueDao;
  late DashboardCubit dashboardCubit;
  late HistoryCubit historyCubit;
  late ScannerCubit scannerCubit;
  late DemoConnectivity connectivity;

  setUpAll(() {
    Hive.init(Directory.systemTemp.createTempSync('home_shell_test').path);
    OfflineQueueDAO.registerAdapters();
    EncryptionService.initialize();
  });

  setUp(() async {
    queueDao = OfflineQueueDAO();
    await queueDao.initialize();
    await queueDao.clear();

    final apiService = ApiService(); // EnvConfig.useMockApi default true
    connectivity = DemoConnectivity();
    dashboardCubit = DashboardCubit(
      repository: DashboardRepositoryImpl(apiService),
    );
    historyCubit = HistoryCubit(
      repository: DashboardRepositoryImpl(apiService),
    );
    scannerCubit = ScannerCubit(
      repository: TicketRepositoryImpl(apiService),
      queueDao: queueDao,
      connectivity: connectivity,
    );
  });

  tearDown(() async {
    await dashboardCubit.close();
    await historyCubit.close();
    await scannerCubit.close();
    connectivity.dispose();
  });

  testWidgets('shell menampilkan Dashboard & History dari API, tanpa crash', (
    tester,
  ) async {
    final session = SessionState()
      ..selectCheckpoint(
        const Checkpoint(
          id: 'cp-01',
          gate: 'Gate 1',
          name: 'Pintu Utama',
          note: 'Shift pagi',
        ),
      );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SessionState>.value(value: session),
          ChangeNotifierProvider<DemoConnectivity>.value(value: connectivity),
          ChangeNotifierProvider(create: (_) => ShellController()),
          BlocProvider<DashboardCubit>.value(value: dashboardCubit),
          BlocProvider<HistoryCubit>.value(value: historyCubit),
          BlocProvider<ScannerCubit>.value(value: scannerCubit),
        ],
        child: const MaterialApp(home: HomeShell()),
      ),
    );
    await settle(tester);

    // Nav bergaya tab: tiga target, dengan Scan sebagai tombol hero di tengah.
    expect(find.byKey(const Key('bottom-navigation')), findsOneWidget);
    expect(find.byKey(const Key('nav-dashboard')), findsOneWidget);
    expect(find.byKey(const Key('nav-scan-hero')), findsOneWidget);
    expect(find.byKey(const Key('nav-history')), findsOneWidget);

    // Tab pertama (Dashboard) memuat metrik hari ini dari API.
    expect(find.text('Visitors'), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Pindah ke tab History: daftar riwayat sudah terisi.
    await tester.tap(find.text('History'));
    await settle(tester);

    expect(find.text('27 scans'), findsOneWidget);
    expect(find.textContaining('TKT-2026-'), findsWidgets);
    expect(tester.takeException(), isNull);

    // Pindah ke tab Scan.
    await tester.tap(find.text('Scan'));
    await settle(tester);

    expect(find.text('Scan Ticket'), findsOneWidget);
    expect(find.text('Enter code manually'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
