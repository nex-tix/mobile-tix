// File: scanner_cubit.dart
// Cubit layar scanner: mode, pengiriman scan, dan sinkronisasi antrean offline.

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/connectivity/connectivity_monitor.dart';
import '../../../../core/data/dao/offline_queue_dao.dart';
import '../../../../core/error/api_failure.dart';
import '../data/models/queued_scan.dart';
import '../data/models/scan_result.dart';
import '../data/ticket_code.dart';
import '../data/repositories/ticket_repository.dart';
import 'scanner_state.dart';

/// Logika layar scanner.
///
/// Tanggung jawab:
/// - memilih endpoint sesuai [ScanMode] (`check` vs `checkIn`);
/// - menjaga hanya satu scan berjalan pada satu waktu;
/// - menyelamatkan scan saat koneksi putus ke [OfflineQueueDAO], dan
///   mengirim ulang antrean begitu koneksi pulih;
/// - membedakan kegagalan yang aman diulang (koneksi) dari yang tidak
///   (timeout/penolakan server), supaya check-in tidak pernah terjadi dua kali.
class ScannerCubit extends Cubit<ScannerState> {
  ScannerCubit({
    required this._repository,
    required OfflineQueueDAO queueDao,
    ConnectivityMonitor? connectivity,
  }) : _queueDao = queueDao,
       _connectivity = connectivity,
       super(ScannerIdle(mode: ScanMode.checkIn, pendingSync: queueDao.size)) {
    // Pantau perubahan koneksi (antrean tidak di-auto-sync saat online;
    // memerlukan konfirmasi manual di dashboard).
    _connectivitySubscription = connectivity?.onlineChanges.listen(
      _onConnectivityChanged,
    );
  }

  final TicketRepository _repository;
  final OfflineQueueDAO _queueDao;
  final ConnectivityMonitor? _connectivity;

  StreamSubscription<bool>? _connectivitySubscription;

  /// Mode aktif. Disimpan di luar state supaya mengganti mode tidak menghapus
  /// hasil scan yang sedang ditampilkan di layar.
  ScanMode _mode = ScanMode.checkIn;

  /// Penjaga supaya dua sync tidak berjalan bersamaan (mis. stream koneksi
  /// memicu sync saat sync lain masih berjalan).
  bool _syncing = false;

  ScanMode get mode => _mode;

  TicketRepository get repository => _repository;

  /// Memeriksa tiket tanpa check-in (dipakai untuk validasi rombongan sebelum check-in).
  Future<ScanResult> checkTicketOnly({
    required String ticketCode,
    required String checkpointId,
  }) {
    final code = TicketCode.parse(ticketCode);
    return _repository.checkTicket(
      ticketCode: code,
      checkpointId: checkpointId,
    );
  }

  /// Jumlah scan yang masih menunggu dikirim, dibaca langsung dari DAO.
  int get pendingSyncCount => _queueDao.size;

  // Cooldown untuk mencegah duplikasi scan cepat (2 detik).
  // Stopwatch monoton — tidak terpengaruh drift NTP/klock mundur seperti DateTime.now().
  String? _lastScannedCode;
  int? _lastScanTick;
  final Stopwatch _cooldownWatch = Stopwatch()..start();
  static const Duration _scanCooldown = Duration(seconds: 2);

  // ==================== MODE ====================

  /// Ganti mode kerja.
  ///
  /// Diabaikan saat sebuah scan sedang berjalan — menukar mode di tengah request
  /// akan mengaburkan endpoint mana yang menghasilkan hasil di layar.
  void setMode(ScanMode mode) {
    if (mode == _mode) return;
    if (state.isProcessing) return;
    _mode = mode;
    emit(ScannerIdle(mode: mode, pendingSync: pendingSyncCount));
  }

  // ==================== SCAN ====================

  /// Kirim satu scan ke endpoint sesuai mode aktif.
  ///
  /// Hasilnya selalu salah satu dari enam verdict, kecuali:
  /// - koneksi putus → [ScannerQueued] (scan disimpan, dikirim saat online);
  /// - kegagalan lain → [ScannerError] (tidak diantrekan).
  Future<void> scanTicket({
    required String ticketCode,
    required String checkpointId,
    int? actualVisitorCount,
  }) async {
    if (state.isProcessing) return; // satu scan diproses pada satu waktu

    // QR POS berisi payload ('TICKET|code=…|transaction=…'), bukan kode tiket
    // polos. Dirapikan di sini supaya kamera, input manual, cooldown, dan
    // antrean offline semuanya bekerja dengan kode yang sama.
    final code = TicketCode.parse(ticketCode);
    final mode = _mode;

    if (code.isEmpty) {
      emit(
        ScannerError(
          mode: mode,
          pendingSync: pendingSyncCount,
          message: 'Kode tiket tidak boleh kosong',
          kind: ScanFailureKind.server,
        ),
      );
      return;
    }

    // Cegah duplikasi cepat: gunakan Stopwatch monotonic untuk selisih.
    final currentTick = _cooldownWatch.elapsedMilliseconds;
    if (_lastScannedCode == code &&
        _lastScanTick != null &&
        (currentTick - _lastScanTick!) < _scanCooldown.inMilliseconds) {
      return; // duplikat dalam cooldown
    }

    // Cegah duplikasi: jika tiket sudah ada di antrean offline,
    // beritahukan status antrean tanpa membuat duplikasi entri atau request.
    if (_queueDao.containsTicket(code)) {
      emit(
        ScannerQueued(
          mode: mode,
          pendingSync: pendingSyncCount,
          ticketCode: code,
          actualVisitorCount: actualVisitorCount,
        ),
      );
      return;
    }

    // Update cooldown tracker
    _lastScannedCode = code;
    _lastScanTick = currentTick;

    emit(
      ScannerProcessing(
        mode: mode,
        pendingSync: pendingSyncCount,
        ticketCode: code,
      ),
    );

    // Sudah tahu offline: jangan buang waktu round-trip yang pasti gagal.
    if (_connectivity?.isOnline == false) {
      await _handleOffline(
        ticketCode: code,
        checkpointId: checkpointId,
        mode: mode,
        actualVisitorCount: actualVisitorCount,
      );
      return;
    }

    try {
      final result = await _send(
        mode: mode,
        ticketCode: code,
        checkpointId: checkpointId,
        actualVisitorCount: actualVisitorCount,
      );
      if (isClosed) return;
      emit(
        ScannerSuccess(
          mode: mode,
          pendingSync: pendingSyncCount,
          result: result,
        ),
      );
    } on ApiFailure catch (failure) {
      if (isClosed) return;
      if (failure.isQueueable) {
        await _handleOffline(
          ticketCode: code,
          checkpointId: checkpointId,
          mode: mode,
          actualVisitorCount: actualVisitorCount,
        );
        return;
      }
      emit(
        ScannerError(
          mode: mode,
          pendingSync: pendingSyncCount,
          message: failure.message,
          kind: _kindOf(failure),
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        ScannerError(
          mode: mode,
          pendingSync: pendingSyncCount,
          message: 'Scan gagal diproses: $error',
          kind: ScanFailureKind.unknown,
        ),
      );
    }
  }

  /// Tutup hasil yang sedang tampil dan kembali siap memindai.
  ///
  /// Dipanggil UI setelah sheet hasil ditutup, sehingga scanner tidak memegang
  /// hasil lama saat petugas memindai tiket berikutnya.
  void acknowledgeResult() {
    if (state is ScannerIdle) return;
    // Reset cooldown tracker agar scan kode sama bisa diproses lagi
    _lastScannedCode = null;
    _lastScanTick = null;
    emit(ScannerIdle(mode: _mode, pendingSync: pendingSyncCount));
  }

  // ==================== OFFLINE QUEUE ====================

  /// Kirim ulang seluruh antrean offline (FIFO) dan kembalikan jumlah yang
  /// berhasil terkirim.
  ///
  /// Aturan sync:
  /// - urutan FIFO dipertahankan supaya check-in sampai ke server sesuai urutan
  ///   kejadian di gate;
  /// - item yang gagal karena **koneksi** menghentikan sync (masih offline) dan
  ///   tidak dihitung sebagai percobaan;
  /// - item yang ditolak server tetap dibiarkan di antrean dengan `retryCount`
  ///   bertambah — item basi akhirnya dibuang sendiri oleh TTL 24 jam milik
  ///   [OfflineQueueDAO], jadi tidak ada check-in yang hilang diam-diam.
  Future<int> processOfflineQueue() async {
    if (_syncing) return 0;
    if (!EnvConfig.enableOfflineQueue) return 0;
    if (_connectivity?.isOnline == false) return 0;

    _syncing = true;
    var synced = 0;
    var failures = <String>[];
    try {
      for (final scan in _queueDao.getAll()) {
        final mode = ScanMode.fromWire(scan.mode);
        try {
          await _send(
            mode: mode,
            ticketCode: scan.ticketCode,
            checkpointId: scan.checkpointId,
            actualVisitorCount: scan.actualVisitorCount,
          );
          await _queueDao.remove(scan.id);
          synced++;
        } on ApiFailure catch (failure) {
          if (failure.isQueueable) {
            // koneksi belum benar-benar pulih — hentikan sync
            failures.add('Connection failed');
            break;
          }
          // kegagalan server — catat, teruskan ke item berikutnya
          failures.add(failure.message);
          await _queueDao.incrementRetry(scan.id);
        } catch (e) {
          failures.add('Error: $e');
          await _queueDao.incrementRetry(scan.id);
        }
      }
    } finally {
      _syncing = false;
    }

    _refreshPendingSync(synced: synced);
    return synced;
  }

  /// Sinkronisasi satu tiket tertentu dari antrean offline ke server.
  Future<ScanResult> syncSingleQueueItem(QueuedScan scan) async {
    if (_connectivity?.isOnline == false) {
      throw const ApiFailure(
        kind: ApiFailureKind.network,
        message: 'Tidak ada koneksi internet',
      );
    }
    final mode = ScanMode.fromWire(scan.mode);
    try {
      final result = await _send(
        mode: mode,
        ticketCode: scan.ticketCode,
        checkpointId: scan.checkpointId,
        actualVisitorCount: scan.actualVisitorCount,
      );
      await _queueDao.remove(scan.id);
      _refreshPendingSync(synced: 1);
      return result;
    } on ApiFailure catch (failure) {
      if (!failure.isQueueable) {
        await _queueDao.incrementRetry(scan.id);
      }
      rethrow;
    } catch (e) {
      await _queueDao.incrementRetry(scan.id);
      rethrow;
    }
  }

  /// Batalkan / hapus satu tiket tertentu dari antrean offline.
  Future<void> cancelQueueItem(String id) async {
    await _queueDao.remove(id);
    _refreshPendingSync();
  }

  Future<ScanResult> _send({
    required ScanMode mode,
    required String ticketCode,
    required String checkpointId,
    int? actualVisitorCount,
  }) {
    return mode == ScanMode.checkIn
        ? _repository.validateAndCheckIn(
            ticketCode: ticketCode,
            checkpointId: checkpointId,
            actualVisitorCount: actualVisitorCount,
          )
        : _repository.checkTicket(
            ticketCode: ticketCode,
            checkpointId: checkpointId,
          );
  }

  /// Simpan scan ke antrean offline, atau laporkan bila antrean dimatikan.
  Future<void> _handleOffline({
    required String ticketCode,
    required String checkpointId,
    required ScanMode mode,
    int? actualVisitorCount,
  }) async {
    final pending = pendingSyncCount;

    if (!EnvConfig.enableOfflineQueue) {
      emit(
        ScannerError(
          mode: mode,
          pendingSync: pending,
          message: 'Tidak ada koneksi internet',
          kind: ScanFailureKind.offline,
        ),
      );
      return;
    }

    try {
      await _queueDao.enqueue(
        ticketCode: ticketCode,
        checkpointId: checkpointId,
        mode: mode.wireValue,
        actualVisitorCount: actualVisitorCount,
      );
      if (isClosed) return;
      emit(
        ScannerQueued(
          mode: mode,
          pendingSync: pendingSyncCount,
          ticketCode: ticketCode,
          actualVisitorCount: actualVisitorCount,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        ScannerError(
          mode: mode,
          pendingSync: pending,
          message: 'Gagal menyimpan scan offline: $error',
          kind: ScanFailureKind.unknown,
        ),
      );
    }
  }

  void _onConnectivityChanged(bool online) {
    // Sesuai alur operasional: saat online kembali, tiket yang menunggu
    // tidak langsung masuk database secara otomatis, melainkan harus dikonfirmasi
    // manual melalui tombol konfirmasi per-tiket di dashboard.
  }

  /// Segarkan angka antrean pada state yang sedang tampil.
  ///
  /// Sengaja hanya menyentuh [ScannerIdle] dan [ScannerQueued]: state
  /// [ScannerProcessing], [ScannerSuccess] dan [ScannerError] sedang dipakai UI
  /// (sheet hasil / pesan error), dan meng-emit ulang akan memicu listener
  /// menampilkan hal yang sama dua kali.
  void _refreshPendingSync({int synced = 0}) {
    if (isClosed) return;
    final pending = pendingSyncCount;
    switch (state) {
      case ScannerIdle s when s.pendingSync != pending:
        emit(ScannerIdle(mode: s.mode, pendingSync: pending));
      case ScannerQueued s when s.pendingSync != pending:
        emit(
          ScannerQueued(
            mode: s.mode,
            pendingSync: pending,
            ticketCode: s.ticketCode,
          ),
        );
      default:
        break;
    }
  }

  static ScanFailureKind _kindOf(ApiFailure failure) => switch (failure.kind) {
    ApiFailureKind.network => ScanFailureKind.offline,
    ApiFailureKind.timeout => ScanFailureKind.timeout,
    ApiFailureKind.unauthorized => ScanFailureKind.unauthorized,
    ApiFailureKind.server => ScanFailureKind.server,
    ApiFailureKind.unknown => ScanFailureKind.unknown,
  };

  @override
  Future<void> close() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    return super.close();
  }
}
