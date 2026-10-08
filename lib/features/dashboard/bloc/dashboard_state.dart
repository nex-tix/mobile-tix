// File: dashboard_state.dart
// State layar dashboard (periode aktif, angka, error).

import '../data/models/dashboard_stats.dart';

export '../data/models/dashboard_stats.dart' show StatsPeriod;

/// State dashboard.
///
/// Ter-seal supaya `switch` di layar wajib menangani setiap kondisi; yang
/// membedakan tiap state adalah *seberapa banyak yang sudah diketahui*, dan itu
/// yang menentukan apakah layar menampilkan skeleton, angka, atau pesan error.
sealed class DashboardState {
  const DashboardState({required this.period, this.stats});

  /// Periode yang sedang ditampilkan / sedang dimuat.
  final StatsPeriod period;

  /// Angka terakhir yang berhasil dimuat; null bila belum pernah berhasil.
  ///
  /// Tetap dibawa saat memuat ulang atau gagal, supaya layar tidak berkedip ke
  /// kosong hanya karena satu request gagal.
  final DashboardStats? stats;

  bool get hasStats => stats != null;

  bool get isLoading => this is DashboardLoading;
}

/// Belum ada permintaan apa pun — layar baru dibuka.
final class DashboardInitial extends DashboardState {
  const DashboardInitial({super.period = StatsPeriod.today});
}

/// Sedang memuat [period]; [stats] berisi angka periode sebelumnya bila ada.
final class DashboardLoading extends DashboardState {
  const DashboardLoading({required super.period, super.stats});
}

/// Angka untuk [period] sudah siap.
final class DashboardReady extends DashboardState {
  const DashboardReady({
    required super.period,
    required DashboardStats super.stats,
  });

  /// Di state ini angkanya selalu ada — pemanggil tidak perlu null-check.
  @override
  DashboardStats get stats => super.stats!;
}

/// Gagal memuat [period]; angka periode sebelumnya (bila ada) tetap dipakai.
final class DashboardFailure extends DashboardState {
  const DashboardFailure({
    required super.period,
    required this.message,
    super.stats,
  });

  /// Pesan siap tampil.
  final String message;
}
