// File: history_cubit_test.dart
// Unit test HistoryCubit: paginasi, filter, kegagalan, dan respons basi.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/core/constants/ticket_status.dart';
import 'package:mobile_tix/core/data/repositories/dashboard_repository.dart';
import 'package:mobile_tix/core/error/api_failure.dart';
import 'package:mobile_tix/features/dashboard/data/models/dashboard_stats.dart';
import 'package:mobile_tix/features/history/bloc/history_cubit.dart';
import 'package:mobile_tix/features/history/bloc/history_state.dart';
import 'package:mobile_tix/features/history/data/models/scan_record.dart';
import 'package:mobile_tix/features/history/data/models/scan_record_page.dart';

/// Satu permintaan riwayat yang diterima repository palsu.
typedef _HistoryCall = ({
  int page,
  String? checkpoint,
  String? status,
  String? date,
});

/// Repository palsu: melayani halaman dari [dataset] dan mencatat setiap panggilan.
class _FakeHistoryRepository implements DashboardRepository {
  final List<_HistoryCall> calls = <_HistoryCall>[];

  List<ScanRecord> dataset = <ScanRecord>[];

  /// Bila diisi, setiap panggilan menunggu completer ini (untuk menguji race).
  Completer<void>? gate;

  /// Bila diisi, panggilan melempar error ini.
  ApiFailure? failure;

  @override
  Future<ScanRecordPage> getTicketHistory({
    int page = 1,
    int pageSize = 10,
    String? checkpoint,
    String? status,
    String? date,
  }) async {
    calls.add((
      page: page,
      checkpoint: checkpoint,
      status: status,
      date: date,
    ));

    final pending = gate;
    if (pending != null) await pending.future;

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

  // Dashboard tidak dipakai di test riwayat.
  @override
  Future<DashboardStats> getSummary({
    StatsPeriod period = StatsPeriod.today,
  }) => throw UnimplementedError('dashboard tidak dipakai di test riwayat');
}

ScanRecord _record(String code, {int minutesAgo = 0}) => ScanRecord(
  ticketCode: code,
  status: TicketStatus.valid,
  scannedAt: DateTime(2026, 10, 8, 12).subtract(Duration(minutes: minutesAgo)),
);

void main() {
  group('HistoryCubit', () {
    late _FakeHistoryRepository repository;
    late HistoryCubit cubit;

    setUp(() {
      repository = _FakeHistoryRepository();
      cubit = HistoryCubit(repository: repository, pageSize: 10);
      addTearDown(cubit.close);
    });

    test('state awal belum memuat apa pun', () {
      expect(cubit.state, isA<HistoryInitial>());
      expect(cubit.state.filter, HistoryFilter.none);
      expect(cubit.state.records, isEmpty);
      expect(cubit.state.hasMore, isFalse);
      expect(repository.calls, isEmpty);
    });

    test('load melewati Loading lalu berakhir Ready di halaman 1', () async {
      repository.dataset = [
        for (var i = 0; i < 25; i++) _record('TKT-$i', minutesAgo: i),
      ];

      final seen = <HistoryState>[];
      final subscription = cubit.stream.listen(seen.add);
      addTearDown(subscription.cancel);

      await cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect(seen.first, isA<HistoryLoading>());
      expect(seen.last, isA<HistoryReady>());

      final ready = cubit.state as HistoryReady;
      expect(ready.page, 1);
      expect(ready.records.length, 10);
      expect(ready.totalItems, 25);
      expect(ready.hasMore, isTrue);
      expect(ready.isComplete, isFalse);
      expect(repository.calls.single.page, 1);
    });

    test('loadMore menambahkan halaman berikutnya', () async {
      repository.dataset = [
        for (var i = 0; i < 25; i++) _record('TKT-$i', minutesAgo: i),
      ];

      await cubit.load();
      await cubit.loadMore();

      final ready = cubit.state as HistoryReady;
      expect(ready.page, 2);
      expect(ready.records.length, 20);
      expect(ready.hasMore, isTrue);
      expect(repository.calls.map((call) => call.page).toList(), [1, 2]);
      // Halaman berbeda tidak menghasilkan baris kembar.
      expect(
        ready.records.map((record) => record.identity).toSet().length,
        20,
      );
    });

    test('loadMore berhenti di halaman terakhir', () async {
      repository.dataset = [
        for (var i = 0; i < 15; i++) _record('TKT-$i', minutesAgo: i),
      ];

      await cubit.load();
      await cubit.loadMore();

      final ready = cubit.state as HistoryReady;
      expect(ready.page, 2);
      expect(ready.records.length, 15);
      expect(ready.hasMore, isFalse);
      expect(ready.isComplete, isTrue);

      // Permintaan berikutnya diabaikan karena sudah habis.
      await cubit.loadMore();
      expect(repository.calls.length, 2);
    });

    test('loadMore mengabaikan baris yang sudah ada (halaman tumpang tindih)',
        () async {
      repository.dataset = [
        for (var i = 0; i < 20; i++) _record('TKT-$i', minutesAgo: i),
      ];

      await cubit.load();
      final firstPage = (cubit.state as HistoryReady).records;

      // Scan baru menyisip di awal sehingga halaman 2 mengulang 5 baris terakhir
      // halaman 1.
      repository.dataset = [
        ...firstPage.take(5),
        ...repository.dataset,
      ];
      await cubit.loadMore();

      final ready = cubit.state as HistoryReady;
      expect(ready.records.length, 15); // 10 + 10 baru − 5 kembar
      expect(
        ready.records.map((record) => record.identity).toSet().length,
        ready.records.length,
      );
    });

    test('menahan daftar lama selama refresh', () async {
      repository.dataset = [_record('TKT-1')];
      await cubit.load();

      final gate = Completer<void>();
      repository.gate = gate;

      final refresh = cubit.refresh();
      expect(cubit.state, isA<HistoryLoading>());
      expect(cubit.state.records.length, 1);

      gate.complete();
      await refresh;

      expect(cubit.state, isA<HistoryReady>());
      expect((cubit.state as HistoryReady).records.length, 1);
    });

    test('kegagalan load menghasilkan HistoryFailure tanpa baris', () async {
      repository.failure = const ApiFailure(
        kind: ApiFailureKind.network,
        message: 'Tidak ada koneksi ke server',
      );

      await cubit.load();

      final failure = cubit.state as HistoryFailure;
      expect(failure.message, 'Tidak ada koneksi ke server');
      expect(failure.records, isEmpty);
      expect(failure.hasRecords, isFalse);
    });

    test('kegagalan loadMore tidak menghapus daftar yang sudah tampil',
        () async {
      repository.dataset = [
        for (var i = 0; i < 25; i++) _record('TKT-$i', minutesAgo: i),
      ];
      await cubit.load();

      repository.failure = const ApiFailure(
        kind: ApiFailureKind.server,
        message: 'Server sibuk',
        statusCode: 503,
      );
      await cubit.loadMore();

      final failure = cubit.state as HistoryFailure;
      expect(failure.message, 'Server sibuk');
      expect(failure.records.length, 10); // daftar halaman 1 tetap ada
      expect(failure.page, 1);
      expect(failure.hasMore, isTrue); // masih bisa dicoba lagi
      expect(failure.canLoadMore, isTrue);
    });

    test('exception tak terduga tetap menjadi HistoryFailure', () async {
      repository.failure = null;
      final throwing = _ThrowingHistoryRepository();
      final throwingCubit = HistoryCubit(repository: throwing);
      addTearDown(throwingCubit.close);

      await throwingCubit.load();

      expect(throwingCubit.state, isA<HistoryFailure>());
      expect(
        (throwingCubit.state as HistoryFailure).message,
        contains('Gagal memuat riwayat'),
      );
    });

    group('filter', () {
      test('applyFilter meneruskan status, gate, dan tanggal ke API', () async {
        await cubit.applyFilter(
          HistoryFilter(
            status: TicketStatus.expired,
            checkpoint: 'Gate B',
            date: DateTime(2026, 10, 7),
          ),
        );

        final call = repository.calls.single;
        expect(call.status, 'expired');
        expect(call.checkpoint, 'Gate B');
        expect(call.date, '2026-10-07');
        expect(call.page, 1);
        expect((cubit.state as HistoryReady).filter.checkpoint, 'Gate B');
      });

      test('applyFilter dengan HistoryFilter.rejected meneruskan status rejected ke API', () async {
        await cubit.applyFilter(HistoryFilter.rejected);

        final call = repository.calls.single;
        expect(call.status, 'rejected');
        expect(call.checkpoint, isNull);
        expect(call.date, isNull);
        expect(call.page, 1);
        expect((cubit.state as HistoryReady).filter.rejectedOnly, isTrue);
      });

      test('applyFilter memuat ulang dari halaman pertama', () async {
        repository.dataset = [
          for (var i = 0; i < 25; i++) _record('TKT-$i', minutesAgo: i),
        ];
        await cubit.load();
        await cubit.loadMore();
        expect((cubit.state as HistoryReady).page, 2);

        await cubit.applyFilter(
          const HistoryFilter(status: TicketStatus.valid),
        );

        expect((cubit.state as HistoryReady).page, 1);
        expect(repository.calls.last.page, 1);
      });

      test('filter yang sama dan sudah siap tidak memicu request baru',
          () async {
        repository.dataset = [_record('TKT-1')];
        await cubit.load();
        expect(repository.calls.length, 1);

        await cubit.applyFilter(HistoryFilter.none);

        expect(repository.calls.length, 1);
      });

      test('filter yang sama setelah gagal dipakai untuk mencoba lagi',
          () async {
        repository.failure = const ApiFailure(
          kind: ApiFailureKind.network,
          message: 'Tidak ada koneksi ke server',
        );
        await cubit.load();
        expect(cubit.state, isA<HistoryFailure>());

        repository.failure = null;
        await cubit.applyFilter(HistoryFilter.none);

        expect(cubit.state, isA<HistoryReady>());
        expect(repository.calls.length, 2);
      });

      test('clearFilter kembali ke seluruh riwayat', () async {
        await cubit.applyFilter(
          const HistoryFilter(status: TicketStatus.valid),
        );

        await cubit.clearFilter();

        expect((cubit.state as HistoryReady).filter, HistoryFilter.none);
        expect(repository.calls.last.status, isNull);
      });

      test('loadMore memakai filter yang sedang aktif', () async {
        repository.dataset = [
          for (var i = 0; i < 25; i++) _record('TKT-$i', minutesAgo: i),
        ];
        await cubit.applyFilter(
          const HistoryFilter(checkpoint: 'Gate A'),
        );
        await cubit.loadMore();

        expect(repository.calls.last.checkpoint, 'Gate A');
        expect(repository.calls.last.page, 2);
      });

      test('respons filter lama dibuang saat filter berganti cepat', () async {
        final gate = Completer<void>();
        repository.gate = gate;

        // Permintaan "semua" ditahan…
        final stalled = cubit.load();
        expect(cubit.state, isA<HistoryLoading>());

        // …lalu petugas memilih filter Valid.
        repository.gate = null;
        await cubit.applyFilter(
          const HistoryFilter(status: TicketStatus.valid),
        );
        expect(
          (cubit.state as HistoryReady).filter.status,
          TicketStatus.valid,
        );

        gate.complete();
        await stalled;

        final ready = cubit.state as HistoryReady;
        expect(ready.filter.status, TicketStatus.valid);
        expect(ready.filter.isUnfiltered, isFalse);
      });
    });
  });
}

/// Repository yang melempar error non-API, untuk menguji jalur catch terakhir.
class _ThrowingHistoryRepository implements DashboardRepository {
  @override
  Future<ScanRecordPage> getTicketHistory({
    int page = 1,
    int pageSize = 10,
    String? checkpoint,
    String? status,
    String? date,
  }) => throw StateError('boom');

  @override
  Future<DashboardStats> getSummary({
    StatsPeriod period = StatsPeriod.today,
  }) => throw UnimplementedError('dashboard tidak dipakai di test riwayat');
}
