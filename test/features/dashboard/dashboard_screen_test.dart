// File: dashboard_screen_test.dart
// Widget test DashboardScreen ↔ DashboardCubit (loading, angka, gagal, periode).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/core/connectivity/demo_connectivity.dart';
import 'package:mobile_tix/core/data/repositories/dashboard_repository.dart';
import 'package:mobile_tix/core/error/api_failure.dart';
import 'package:mobile_tix/features/auth/logic/session_state.dart';
import 'package:mobile_tix/features/dashboard/bloc/dashboard_cubit.dart';
import 'package:mobile_tix/features/dashboard/data/models/dashboard_stats.dart';
import 'package:mobile_tix/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:mobile_tix/features/history/data/models/scan_record_page.dart';
import 'package:provider/provider.dart';

/// Repository palsu: menjawab seluruh periode dari tabel tetap.
class _FakeDashboardRepository implements DashboardRepository {
  final List<StatsPeriod> requested = <StatsPeriod>[];

  ApiFailure? failure;

  @override
  Future<DashboardStats> getSummary({
    StatsPeriod period = StatsPeriod.today,
  }) async {
    requested.add(period);

    final error = failure;
    if (error != null) throw error;

    return DashboardStats(
      period: period,
      totalVisitors: period == StatsPeriod.today ? 128 : 3412,
      validTickets: period == StatsPeriod.today ? 121 : 3204,
      rejectedTickets: period == StatsPeriod.today ? 7 : 208,
    );
  }

  @override
  Future<ScanRecordPage> getTicketHistory({
    int page = 1,
    int pageSize = 10,
    String? checkpoint,
    String? status,
    String? date,
  }) => throw UnimplementedError('riwayat tidak dipakai di test dashboard');
}

/// Beberapa pump pendek — cukup untuk menjalankan post-frame callback dan
/// menyelesaikan Future repository, tanpa menunggu animasi skeleton yang berulang.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 20));
}

void main() {
  late _FakeDashboardRepository repository;
  late DashboardCubit cubit;

  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionState>(create: (_) => SessionState()),
        ChangeNotifierProvider<DemoConnectivity>(
          create: (_) => DemoConnectivity(),
        ),
        BlocProvider<DashboardCubit>.value(value: cubit),
      ],
      child: MaterialApp(home: child),
    );
  }

  setUp(() {
    repository = _FakeDashboardRepository();
    cubit = DashboardCubit(repository: repository);
  });

  tearDown(() => cubit.close());

  testWidgets('memuat hari ini lalu menampilkan angka periode itu', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const DashboardScreen()));

    expect(repository.requested, [StatsPeriod.today]);

    await settle(tester);

    expect(find.text('Visitors'), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
    expect(find.text('Valid'), findsOneWidget);
    expect(find.text('121'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('menukar periode memuat dan menampilkan angka bulan ini', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const DashboardScreen()));
    await settle(tester);

    await tester.tap(find.text('This Month'));
    await settle(tester);

    expect(repository.requested, [StatsPeriod.today, StatsPeriod.month]);
    expect(find.text('3412'), findsOneWidget);
    expect(find.text('3204'), findsOneWidget);
    expect(find.text('208'), findsOneWidget);
    // Angka periode sebelumnya sudah tidak ditampilkan.
    expect(find.text('128'), findsNothing);
  });

  testWidgets('kegagalan permintaan pertama menampilkan pesan dan tombol coba',
      (tester) async {
    repository.failure = const ApiFailure(
      kind: ApiFailureKind.network,
      message: 'Tidak ada koneksi ke server',
    );

    await tester.pumpWidget(wrap(const DashboardScreen()));
    await settle(tester);

    expect(find.text('Metrik tidak dapat dimuat'), findsOneWidget);
    expect(find.text('Tidak ada koneksi ke server'), findsOneWidget);
    // Tidak ada angka yang dikarang saat data belum pernah ada.
    expect(find.text('0'), findsNothing);

    repository.failure = null;
    await tester.tap(find.text('Coba lagi'));
    await settle(tester);

    expect(find.text('128'), findsOneWidget);
    expect(find.text('Metrik tidak dapat dimuat'), findsNothing);
  });

  testWidgets('kegagalan saat memuat ulang menahan angka lama', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const DashboardScreen()));
    await settle(tester);
    expect(find.text('128'), findsOneWidget);

    repository.failure = const ApiFailure(
      kind: ApiFailureKind.server,
      message: 'Server sibuk',
      statusCode: 503,
    );
    await cubit.refresh();
    await settle(tester);

    // Angka lama tetap tampil, plus banner kesalahan.
    expect(find.text('128'), findsOneWidget);
    expect(find.text('Server sibuk'), findsOneWidget);
    expect(find.text('Metrik tidak dapat dimuat'), findsNothing);
  });
}
