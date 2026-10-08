// File: history_cubit.dart
// Cubit layar riwayat: daftar terhalaman + filter gate/status/tanggal.

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/repositories/dashboard_repository.dart';
import '../../../../core/error/api_failure.dart';
import '../data/models/scan_record.dart';
import '../data/models/scan_record_page.dart';
import 'history_state.dart';

/// Logika layar riwayat scan.
///
/// Menyimpan satu daftar yang tumbuh ke bawah: halaman pertama saat dibuka atau
/// saat filter berubah, lalu halaman berikutnya ditambahkan setiap kali petugas
/// menelusuri lebih jauh. Filter selalu dipakai ulang saat memuat halaman
/// berikutnya, sehingga daftar tidak pernah tercampur antar filter.
class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({required this._repository, this.pageSize = 10})
    : super(const HistoryInitial());

  final DashboardRepository _repository;

  /// Jumlah baris per halaman.
  final int pageSize;

  /// Nomor permintaan terakhir — respons basi (filter lama yang baru selesai
  /// setelah filter baru dipilih) dibuang.
  int _requestId = 0;

  /// Muat halaman pertama untuk filter yang sedang aktif.
  Future<void> load() =>
      _fetchFirstPage(state.filter, keepRecords: false);

  /// Muat ulang filter yang sedang aktif sambil menahan daftar yang sudah tampil
  /// (pull-to-refresh).
  Future<void> refresh() =>
      _fetchFirstPage(state.filter, keepRecords: true);

  /// Ganti filter lalu muat ulang dari halaman pertama.
  ///
  /// Filter yang sama dan datanya sudah siap tidak memicu request baru; filter
  /// yang sama setelah kegagalan justru dipakai untuk mencoba lagi.
  Future<void> applyFilter(HistoryFilter filter) {
    if (filter == state.filter && state is HistoryReady) {
      return Future<void>.value();
    }
    return _fetchFirstPage(filter, keepRecords: false);
  }

  /// Buang penyaring dan muat ulang seluruh riwayat.
  Future<void> clearFilter() => applyFilter(HistoryFilter.none);

  /// Tambahkan halaman berikutnya ke daftar yang sedang tampil.
  Future<void> loadMore() async {
    final current = state;
    if (current is! HistoryReady || !current.canLoadMore) return;

    final filter = current.filter;
    final request = ++_requestId;

    emit(
      HistoryReady(
        filter: filter,
        records: current.records,
        page: current.page,
        totalItems: current.totalItems,
        hasMore: true,
        loadingMore: true,
      ),
    );

    try {
      final result = await _request(filter: filter, page: current.page + 1);
      if (isClosed || request != _requestId) return;

      emit(
        HistoryReady(
          filter: filter,
          // Halaman bisa tumpang tindih bila ada scan baru masuk di sela dua
          // pengambilan — baris yang sudah ada tidak digandakan.
          records: _appendUnique(current.records, result.items),
          page: current.page + 1,
          totalItems: result.totalItems,
          hasMore: result.hasMore,
        ),
      );
    } on ApiFailure catch (failure) {
      if (isClosed || request != _requestId) return;
      emit(
        HistoryFailure(
          filter: filter,
          message: failure.message,
          records: current.records,
          page: current.page,
          totalItems: current.totalItems,
          hasMore: current.hasMore,
        ),
      );
    } catch (error) {
      if (isClosed || request != _requestId) return;
      emit(
        HistoryFailure(
          filter: filter,
          message: 'Gagal memuat halaman berikutnya: $error',
          records: current.records,
          page: current.page,
          totalItems: current.totalItems,
          hasMore: current.hasMore,
        ),
      );
    }
  }

  // ==================== INTERNAL ====================

  Future<void> _fetchFirstPage(
    HistoryFilter filter, {
    required bool keepRecords,
  }) async {
    final request = ++_requestId;
    final previous = keepRecords ? state.records : const <ScanRecord>[];

    emit(HistoryLoading(filter: filter, records: previous));

    try {
      final result = await _request(filter: filter, page: 1);
      if (isClosed || request != _requestId) return;

      emit(
        HistoryReady(
          filter: filter,
          records: result.items,
          page: 1,
          totalItems: result.totalItems,
          hasMore: result.hasMore,
        ),
      );
    } on ApiFailure catch (failure) {
      if (isClosed || request != _requestId) return;
      emit(
        HistoryFailure(
          filter: filter,
          message: failure.message,
          records: previous,
        ),
      );
    } catch (error) {
      if (isClosed || request != _requestId) return;
      emit(
        HistoryFailure(
          filter: filter,
          message: 'Gagal memuat riwayat: $error',
          records: previous,
        ),
      );
    }
  }

  Future<ScanRecordPage> _request({
    required HistoryFilter filter,
    required int page,
  }) {
    return _repository.getTicketHistory(
      page: page,
      pageSize: pageSize,
      checkpoint: filter.checkpoint,
      status: filter.statusParam,
      date: filter.dateParam,
    );
  }

  /// Gabungkan [incoming] setelah [existing] tanpa menggandakan baris.
  static List<ScanRecord> _appendUnique(
    List<ScanRecord> existing,
    List<ScanRecord> incoming,
  ) {
    final merged = List<ScanRecord>.of(existing);
    final seen = existing.map((record) => record.identity).toSet();
    for (final record in incoming) {
      if (seen.add(record.identity)) merged.add(record);
    }
    return merged;
  }
}
