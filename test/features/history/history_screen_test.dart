// File: history_screen_test.dart
// Widget test HistoryScreen ↔ HistoryCubit (daftar, filter, kosong, gagal).

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/core/constants/ticket_status.dart';
import 'package:mobile_tix/core/data/repositories/dashboard_repository.dart';
import 'package:mobile_tix/core/error/api_failure.dart';
import 'package:mobile_tix/features/dashboard/data/models/dashboard_stats.dart';
import 'package:mobile_tix/features/history/bloc/history_cubit.dart';
import 'package:mobile_tix/features/history/data/models/scan_record.dart';
import 'package:mobile_tix/features/history/data/models/scan_record_page.dart';
import 'package:mobile_tix/features/history/presentation/screens/history_screen.dart';

/// Satu permintaan riwayat yang diterima repository palsu.
typedef _Call = ({int page, String? checkpoint, String? status, String? date});

class _FakeHistoryRepository implements DashboardRepository {
  final List<_Call> calls = <_Call>[];

  List<ScanRecord> dataset = <ScanRecord>[];

  ApiFailure? failure;

  @override
  Future<ScanRecordPage> getTicketHistory({
    int page = 1,
    int pageSize = 10,
    String? checkpoint,
    String? status,
    String? date,
  }) async {
    calls.add((page: page, checkpoint: checkpoint, status: status, date: date));

    final error = failure;
    if (error != null) throw error;

    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, dataset.length);
    final items = start >= dataset.length
        ? const <ScanRecord>[]
        : dataset.sublist(start, end);
    final totalPages = dataset.isEmpty
        ? 0
        : (dataset.length + pageSize - 1) ~/ pageSize;

    return ScanRecordPage(
      items: items,
      page: page,
      pageSize: pageSize,
      totalItems: dataset.length,
      totalPages: totalPages,
    );
  }

  @override
  Future<DashboardStats> getSummary({StatsPeriod period = StatsPeriod.today}) =>
      throw UnimplementedError('dashboard tidak dipakai di test riwayat');
}

ScanRecord record(String code, {TicketStatus status = TicketStatus.valid}) =>
    ScanRecord(
      ticketCode: code,
      status: status,
      scannedAt: DateTime(2026, 10, 8, 9, 30),
      checkpoint: 'Gate A',
      visitorCount: 1,
    );

/// Beberapa pump pendek — cukup untuk post-frame callback + Future repository,
/// tanpa menunggu animasi spinner yang berputar terus.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 20));
}

void main() {
  late _FakeHistoryRepository repository;
  late HistoryCubit cubit;

  Widget wrap(Widget child) {
    return EasyLocalization(
      supportedLocales: const [Locale('id'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('id'),
      startLocale: const Locale('id'),
      assetLoader: const RootBundleAssetLoader(),
      child: BlocProvider<HistoryCubit>.value(
        value: cubit,
        child: MaterialApp(home: child),
      ),
    );
  }

  setUp(() {
    repository = _FakeHistoryRepository();
    cubit = HistoryCubit(repository: repository, pageSize: 10);
  });

  tearDown(() => cubit.close());

  testWidgets('memuat daftar dan menampilkan tiap baris beserta jumlahnya', (
    tester,
  ) async {
    repository.dataset = [
      record('TKT-2026-001245'),
      record('TKT-2026-001244', status: TicketStatus.alreadyUsed),
    ];

    await tester.pumpWidget(wrap(const HistoryScreen()));
    await settle(tester);

    expect(repository.calls.single.page, 1);
    expect(find.text('TKT-2026-001245'), findsOneWidget);
    expect(find.text('TKT-2026-001244'), findsOneWidget);
    expect(find.text('2 scans'), findsOneWidget);
  });

  testWidgets('riwayat kosong menampilkan pesan, bukan daftar kosong', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const HistoryScreen()));
    await settle(tester);

    expect(find.text('Tidak ada data tiket'), findsOneWidget);
    expect(find.text('0 scans'), findsOneWidget);
  });

  testWidgets('dropdown Rejected memakai nilai kelompok ke API', (
    tester,
  ) async {
    repository.dataset = [record('TKT-1')];

    await tester.pumpWidget(wrap(const HistoryScreen()));
    await settle(tester);

    await tester.tap(find.byKey(const Key('history-status-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rejected').last);
    await settle(tester);

    expect(repository.calls.last.status, 'rejected');
    expect(repository.calls.last.page, 1);
  });

  testWidgets('dropdown Valid menyaring dengan verdict pasti', (tester) async {
    repository.dataset = [record('TKT-1')];

    await tester.pumpWidget(wrap(const HistoryScreen()));
    await settle(tester);

    await tester.tap(find.byKey(const Key('history-status-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valid').last);
    await settle(tester);

    expect(repository.calls.last.status, 'valid');
  });

  testWidgets('kembali ke All melepas penyaring', (tester) async {
    repository.dataset = [record('TKT-1')];

    await tester.pumpWidget(wrap(const HistoryScreen()));
    await settle(tester);

    await tester.tap(find.byKey(const Key('history-status-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valid').last);
    await settle(tester);
    await tester.tap(find.byKey(const Key('history-status-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All').last);
    await settle(tester);

    expect(repository.calls.last.status, isNull);
  });

  testWidgets('search bar menyaring riwayat dari kode tiket', (tester) async {
    repository.dataset = [record('TKT-ALPHA'), record('TKT-BETA')];

    await tester.pumpWidget(wrap(const HistoryScreen()));
    await settle(tester);

    await tester.enterText(
      find.byKey(const Key('history-search-field')),
      'ALPHA',
    );
    await tester.pump();

    expect(find.text('TKT-ALPHA'), findsOneWidget);
    expect(find.text('TKT-BETA'), findsNothing);
  });

  testWidgets('sort tamu terbanyak menaruh visitorCount terbesar di atas', (
    tester,
  ) async {
    repository.dataset = [
      ScanRecord(
        ticketCode: 'TKT-SMALL',
        status: TicketStatus.valid,
        scannedAt: DateTime(2026, 10, 8, 9, 30),
        checkpoint: 'Gate A',
        visitorCount: 1,
      ),
      ScanRecord(
        ticketCode: 'TKT-BIG',
        status: TicketStatus.valid,
        scannedAt: DateTime(2026, 10, 8, 9, 30),
        checkpoint: 'Gate A',
        visitorCount: 5,
      ),
    ];

    await tester.pumpWidget(wrap(const HistoryScreen()));
    await settle(tester);

    await tester.tap(find.byKey(const Key('history-sort-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tamu terbanyak').last);
    await tester.pump();

    final bigTop = tester.getTopLeft(find.text('TKT-BIG')).dy;
    final smallTop = tester.getTopLeft(find.text('TKT-SMALL')).dy;
    expect(bigTop, lessThan(smallTop));
  });

  testWidgets('kegagalan tanpa data menampilkan pesan error dan tombol muat', (
    tester,
  ) async {
    repository.failure = const ApiFailure(
      kind: ApiFailureKind.network,
      message: 'Tidak ada koneksi ke server',
    );

    await tester.pumpWidget(wrap(const HistoryScreen()));
    await settle(tester);

    expect(find.text('Tidak ada koneksi ke server'), findsOneWidget);
    expect(find.text('Muat ulang'), findsOneWidget);

    repository.failure = null;
    repository.dataset = [record('TKT-1')];
    await tester.tap(find.text('Muat ulang'));
    await settle(tester);

    expect(find.text('TKT-1'), findsOneWidget);
  });
}
