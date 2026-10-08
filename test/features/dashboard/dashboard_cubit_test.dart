// File: dashboard_cubit_test.dart
// Unit test DashboardCubit: periode, muat ulang, kegagalan, dan respons basi.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/core/data/repositories/dashboard_repository.dart';
import 'package:mobile_tix/core/error/api_failure.dart';
import 'package:mobile_tix/features/dashboard/bloc/dashboard_cubit.dart';
import 'package:mobile_tix/features/dashboard/bloc/dashboard_state.dart';
import 'package:mobile_tix/features/dashboard/data/models/dashboard_stats.dart';
import 'package:mobile_tix/features/history/data/models/scan_record_page.dart';

/// Repository palsu: mencatat periode yang diminta dan bisa ditahan/di-gagalkan.
class _FakeDashboardRepository implements DashboardRepository {
  final List<StatsPeriod> requested = <StatsPeriod>[];

  /// Bila diisi, setiap pemanggilan menunggu completer ini (untuk menguji race).
  Completer<void>? gate;

  /// Bila diisi, pemanggilan melempar error ini.
  ApiFailure? failure;

  @override
  Future<DashboardStats> getSummary({
    StatsPeriod period = StatsPeriod.today,
  }) async {
    requested.add(period);

    final pending = gate;
    if (pending != null) await pending.future;

    final error = failure;
    if (error != null) throw error;

    return DashboardStats(
      period: period,
      totalVisitors: period == StatsPeriod.today ? 128 : 3412,
      validTickets: period == StatsPeriod.today ? 121 : 3204,
      rejectedTickets: period == StatsPeriod.today ? 7 : 208,
      byCheckpoint: period == StatsPeriod.today
          ? const {'Gate A': 70, 'Gate B': 58}
          : const {'Gate A': 1800, 'Gate B': 1612},
      byVisitorType: period == StatsPeriod.today
          ? const {'Regular': 90, 'VIP': 38}
          : const {'Regular': 2500, 'VIP': 912},
    );
  }

  // Riwayat tidak dipakai di test dashboard.
  @override
  Future<ScanRecordPage> getTicketHistory({
    int page = 1,
    int pageSize = 10,
    String? checkpoint,
    String? status,
    String? date,
  }) => throw UnimplementedError('riwayat tidak dipakai di test dashboard');
}

void main() {
  group('DashboardCubit', () {
    late _FakeDashboardRepository repository;
    late DashboardCubit cubit;

    setUp(() {
      repository = _FakeDashboardRepository();
      cubit = DashboardCubit(repository: repository);
      addTearDown(cubit.close);
    });

    test('state awal belum memuat apa pun', () {
      expect(cubit.state, isA<DashboardInitial>());
      expect(cubit.state.period, StatsPeriod.today);
      expect(cubit.state.stats, isNull);
      expect(cubit.state.hasStats, isFalse);
      expect(repository.requested, isEmpty);
    });

    test('loadToday melewati Loading lalu berakhir Ready', () async {
      final seen = <DashboardState>[];
      final subscription = cubit.stream.listen(seen.add);
      addTearDown(subscription.cancel);

      await cubit.loadToday();
      await Future<void>.delayed(Duration.zero);

      expect(repository.requested, [StatsPeriod.today]);
      expect(seen.first, isA<DashboardLoading>());
      expect(seen.last, isA<DashboardReady>());

      final ready = cubit.state as DashboardReady;
      expect(ready.period, StatsPeriod.today);
      expect(ready.stats.totalVisitors, 128);
      expect(ready.stats.validTickets, 121);
      expect(ready.stats.rejectedTickets, 7);
      expect(ready.stats.byCheckpoint, {'Gate A': 70, 'Gate B': 58});
      expect(ready.stats.byVisitorType, {'Regular': 90, 'VIP': 38});
    });

    test('loadMonth mengambil periode bulan ini dengan breakdown lengkap', () async {
      await cubit.loadMonth();

      expect(repository.requested, [StatsPeriod.month]);
      final ready = cubit.state as DashboardReady;
      expect(ready.period, StatsPeriod.month);
      expect(ready.stats.period, StatsPeriod.month);
      expect(ready.stats.totalVisitors, 3412);
      expect(ready.stats.validTickets, 3204);
      expect(ready.stats.rejectedTickets, 208);
      expect(ready.stats.byCheckpoint, {'Gate A': 1800, 'Gate B': 1612});
      expect(ready.stats.byVisitorType, {'Regular': 2500, 'VIP': 912});
    });

    test('select tidak memuat ulang periode yang sudah tampil', () async {
      await cubit.loadToday();
      expect(repository.requested.length, 1);

      await cubit.select(StatsPeriod.today);

      expect(repository.requested.length, 1);
      expect(cubit.state, isA<DashboardReady>());
    });

    test('select berpindah periode saat periode berbeda', () async {
      await cubit.loadToday();
      await cubit.select(StatsPeriod.month);

      expect(repository.requested, [StatsPeriod.today, StatsPeriod.month]);
      expect((cubit.state as DashboardReady).period, StatsPeriod.month);
    });

    test('select mencoba lagi setelah kegagalan', () async {
      repository.failure = const ApiFailure(
        kind: ApiFailureKind.network,
        message: 'Tidak ada koneksi ke server',
      );

      await cubit.loadToday();
      expect(cubit.state, isA<DashboardFailure>());

      repository.failure = null;
      await cubit.select(StatsPeriod.today);

      expect(cubit.state, isA<DashboardReady>());
      expect(repository.requested.length, 2);
    });

    test('kegagalan API menjadi DashboardFailure dengan pesan server', () async {
      repository.failure = const ApiFailure(
        kind: ApiFailureKind.server,
        message: 'Periode tidak valid',
        statusCode: 422,
      );

      await cubit.loadToday();

      final failure = cubit.state as DashboardFailure;
      expect(failure.message, 'Periode tidak valid');
      expect(failure.period, StatsPeriod.today);
      expect(failure.stats, isNull);
    });

    test('refresh menahan angka lama selama memuat ulang', () async {
      await cubit.loadToday();

      final gate = Completer<void>();
      repository.gate = gate;

      final refresh = cubit.refresh();
      expect(cubit.state, isA<DashboardLoading>());
      expect(cubit.state.stats, isNotNull);
      expect(cubit.state.stats!.totalVisitors, 128);

      gate.complete();
      await refresh;

      expect(cubit.state, isA<DashboardReady>());
    });

    test('kegagalan saat memuat ulang tidak menghapus angka lama', () async {
      await cubit.loadToday();

      repository.failure = const ApiFailure(
        kind: ApiFailureKind.network,
        message: 'Tidak ada koneksi ke server',
      );
      await cubit.refresh();

      final failure = cubit.state as DashboardFailure;
      expect(failure.message, 'Tidak ada koneksi ke server');
      expect(failure.stats, isNotNull);
      expect(failure.stats!.totalVisitors, 128);
      expect(failure.hasStats, isTrue);
    });

    test('respons basi dibuang saat periode berganti cepat', () async {
      final gate = Completer<void>();
      repository.gate = gate;

      // Permintaan hari ini ditahan…
      final firstRequest = cubit.loadToday();
      expect(cubit.state, isA<DashboardLoading>());
      expect(cubit.state.period, StatsPeriod.today);

      // …lalu petugas langsung pindah ke bulan ini.
      repository.gate = null;
      await cubit.loadMonth();
      expect((cubit.state as DashboardReady).period, StatsPeriod.month);

      // Permintaan lama akhirnya selesai — hasilnya harus diabaikan.
      gate.complete();
      await firstRequest;

      final state = cubit.state as DashboardReady;
      expect(state.period, StatsPeriod.month);
      expect(state.stats.period, StatsPeriod.month);
      expect(state.stats.totalVisitors, 3412);
    });

    test('exception tak terduga tetap menjadi DashboardFailure', () async {
      repository.failure = null;
      final cubitWithThrow = DashboardCubit(
        repository: _ThrowingDashboardRepository(),
      );
      addTearDown(cubitWithThrow.close);

      await cubitWithThrow.loadToday();

      expect(cubitWithThrow.state, isA<DashboardFailure>());
      expect(
        (cubitWithThrow.state as DashboardFailure).message,
        contains('Gagal memuat dashboard'),
      );
    });
  });
}

/// Repository yang melempar error non-API, untuk menguji jalur catch terakhir.
class _ThrowingDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardStats> getSummary({
    StatsPeriod period = StatsPeriod.today,
  }) => throw StateError('boom');

  @override
  Future<ScanRecordPage> getTicketHistory({
    int page = 1,
    int pageSize = 10,
    String? checkpoint,
    String? status,
    String? date,
  }) => throw UnimplementedError('riwayat tidak dipakai di test dashboard');
}
