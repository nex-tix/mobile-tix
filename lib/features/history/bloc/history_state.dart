// File: history_state.dart
// State layar riwayat (filter aktif, baris yang sudah dimuat, paginasi).

import '../data/models/history_filter.dart';
import '../data/models/scan_record.dart';

export '../data/models/history_filter.dart' show HistoryFilter;

/// State riwayat.
///
/// Ter-seal supaya `switch` di layar wajib menangani setiap kondisi. Semua state
/// membawa [records] yang sudah dimiliki layar — itulah yang membuat kegagalan
/// pengambilan halaman berikutnya tidak mengosongkan daftar yang sudah tampil.
sealed class HistoryState {
  const HistoryState({
    required this.filter,
    this.records = const <ScanRecord>[],
    this.page = 0,
    this.totalItems = 0,
    this.hasMore = false,
    this.loadingMore = false,
  });

  /// Penyaring yang sedang aktif.
  final HistoryFilter filter;

  /// Baris yang sudah dimuat, terbaru di atas.
  final List<ScanRecord> records;

  /// Nomor halaman terakhir yang berhasil dimuat (0 = belum ada).
  final int page;

  /// Total baris untuk filter ini menurut server (0 bila tidak dikirim).
  final int totalItems;

  /// Masih ada halaman berikutnya.
  final bool hasMore;

  /// Halaman berikutnya sedang diambil (daftar tetap tampil).
  final bool loadingMore;

  bool get hasRecords => records.isNotEmpty;

  /// True saat pengambilan pertama untuk filter ini masih berjalan.
  bool get isLoading => this is HistoryLoading;

  /// Bisa memuat halaman berikutnya sekarang.
  bool get canLoadMore => hasMore && !loadingMore;
}

/// Belum ada permintaan apa pun.
final class HistoryInitial extends HistoryState {
  const HistoryInitial({super.filter = HistoryFilter.none});
}

/// Halaman pertama sedang diambil.
///
/// [records] berisi daftar lama saat ini terjadi karena refresh — layar boleh
/// tetap menggambarnya sementara data baru menyusul.
final class HistoryLoading extends HistoryState {
  const HistoryLoading({
    required super.filter,
    super.records,
    super.page,
    super.totalItems,
    super.hasMore,
  });
}

/// Daftar untuk [filter] siap (satu halaman atau lebih).
final class HistoryReady extends HistoryState {
  const HistoryReady({
    required super.filter,
    required super.records,
    required super.page,
    super.totalItems,
    super.hasMore,
    super.loadingMore,
  });

  /// Semua baris untuk filter ini sudah dimuat.
  bool get isComplete => !hasMore;
}

/// Pengambilan gagal.
///
/// [records] tetap dibawa supaya daftar yang sudah tampil tidak hilang; UI
/// memutuskan apakah menampilkan layar error (daftar kosong) atau banner ringan
/// di atas daftar yang ada.
final class HistoryFailure extends HistoryState {
  const HistoryFailure({
    required super.filter,
    required this.message,
    super.records,
    super.page,
    super.totalItems,
    super.hasMore,
    super.loadingMore,
  });

  /// Pesan siap tampil.
  final String message;
}
