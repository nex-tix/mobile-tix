// File: dashboard_cubit.dart
// Cubit layar dashboard: metrik hari ini & bulan ini.

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/repositories/dashboard_repository.dart';
import '../../../../core/error/api_failure.dart';
import 'dashboard_state.dart';

/// Logika layar dashboard.
///
/// Satu sumber angka untuk kedua periode: petugas menukar Today ↔ This Month dan
/// angka yang tampil selalu angka periode yang terakhir diminta — respons yang
/// sudah basi (mis. periode lama yang baru selesai setelah periode baru dipilih)
/// dibuang, bukan ditampilkan.
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({required this._repository}) : super(const DashboardInitial());

  final DashboardRepository _repository;

  /// Nomor permintaan terakhir. Respons dengan nomor lama diabaikan.
  int _requestId = 0;

  /// Muat metrik periode hari ini.
  Future<void> loadToday() => load(StatsPeriod.today);

  /// Muat metrik periode bulan ini.
  Future<void> loadMonth() => load(StatsPeriod.month);

  /// Tukar periode. Tidak memuat ulang bila periode itu sudah tampil — kecuali
  /// belum ada angka sama sekali (mis. percobaan sebelumnya gagal).
  Future<void> select(StatsPeriod period) {
    if (state.period == period && state is DashboardReady) {
      return Future<void>.value();
    }
    return load(period);
  }

  /// Muat ulang periode yang sedang tampil (aksi refresh manual).
  Future<void> refresh() => load(state.period);

  /// Ambil [period] dari API.
  ///
  /// Saat memuat ulang, angka periode sebelumnya tetap ikut di-emit
  /// ([DashboardLoading.stats]) sehingga layar bisa menahan angka lama daripada
  /// berkedip kosong.
  Future<void> load(StatsPeriod period) async {
    final previous = state.stats;
    final request = ++_requestId;
    emit(DashboardLoading(period: period, stats: previous));

    try {
      final stats = await _repository.getSummary(period: period);
      if (isClosed || request != _requestId) return;
      emit(DashboardReady(period: period, stats: stats));
    } on ApiFailure catch (failure) {
      if (isClosed || request != _requestId) return;
      emit(
        DashboardFailure(
          period: period,
          message: failure.message,
          stats: previous,
        ),
      );
    } catch (error) {
      if (isClosed || request != _requestId) return;
      emit(
        DashboardFailure(
          period: period,
          message: 'Gagal memuat dashboard: $error',
          stats: previous,
        ),
      );
    }
  }
}
