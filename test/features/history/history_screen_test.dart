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

    var list = dataset;
    if (status != null && status.isNotEmpty) {
      list = status == 'valid'
          ? list.where((item) => item.isValid).toList()
          : list.where((item) => item.isRejected).toList();
    }
    if (checkpoint != null && checkpoint.isNotEmpty && checkpoint != 'all') {
      list = list.where((item) => item.checkpoint == checkpoint).toList();
    }

    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, list.length);
    final items = start >= list.length
        ? const <ScanRecord>[]
        : list.sublist(start, end);
    final totalPages = list.isEmpty
        ? 0
        : (list.length + pageSize - 1) ~/ pageSize;

    return ScanRecordPage(
      items: items,
      page: page,
      pageSize: pageSize,
      totalItems: list.length,
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

  testWidgets('memuat daftar hanya tiket valid dan menyembunyikan yang ditolak', (
    tester,
  ) async {
    repository.dataset = [
      record('TKT-2026-001245'),
      record('TKT-2026-001244', status: TicketStatus.alreadyUsed),
    ];

    await tester.pumpWidget(wrap(const HistoryScreen()));
    await settle(tester);

    expect(repository.calls.single.page, 1);
    expect(repository.calls.single.status, 'valid');
    expect(find.text('TKT-2026-001245'), findsOneWidget);
    expect(find.text('TKT-2026-001244'), findsNothing);
    expect(find.text('1 scans'), findsOneWidget);
  });

  testWidgets('riwayat kosong menampilkan pesan, bukan daftar kosong', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const HistoryScreen()));
    await settle(tester);

    expect(find.text('Tidak ada data tiket'), findsOneWidget);
    expect(find.text('0 scans'), findsOneWidget);
  });

  testWidgets('tidak ada filter status ditolak di UI dan meminta tiket valid', (
    tester,
  ) async {
    repository.dataset = [record('TKT-1')];

    await tester.pumpWidget(wrap(const HistoryScreen()));
    await settle(tester);

    expect(find.byKey(const Key('history-status-filter')), findsNothing);
    expect(repository.calls.first.status, 'valid');
  });

  testWidgets('filter Gate tetap mempertahankan status valid', (tester) async {
    repository.dataset = [
      record('TKT-1'),
      ScanRecord(
        ticketCode: 'TKT-2',
        status: TicketStatus.valid,
        scannedAt: DateTime(2026, 10, 8, 9, 30),
        checkpoint: 'Gate B',
        visitorCount: 1,
      ),
    ];

    await tester.pumpWidget(wrap(const HistoryScreen()));
    await settle(tester);

    await tester.tap(find.byKey(const Key('history-gate-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gate: Gate B').last);
    await settle(tester);

    expect(repository.calls.last.status, 'valid');
    expect(repository.calls.last.checkpoint, 'Gate B');
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
