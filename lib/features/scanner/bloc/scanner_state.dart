// File: scanner_state.dart
// State layar scanner (mode, proses scan, hasil, antrean offline).

import '../data/models/scan_result.dart';

export '../data/models/scan_mode.dart';

/// Kenapa sebuah scan tidak menghasilkan verdict.
///
/// Dipakai UI untuk memilih pesan & aksi yang tepat tanpa membaca teks error.
enum ScanFailureKind {
  /// Koneksi putus — scan sudah masuk antrean offline.
  offline,

  /// Server tidak menjawab tepat waktu. Scan **tidak** diantrekan karena
  /// request mungkin sudah diproses server.
  timeout,

  /// Token ditolak; sesi perlu diperbarui.
  unauthorized,

  /// Server menolak permintaan.
  server,

  /// Penyebab lain.
  unknown,
}

/// State scanner. Ter-seal supaya `switch` di UI wajib menangani setiap kondisi
/// — tidak ada layar yang diam-diam melewatkan satu hasil scan.
sealed class ScannerState {
  const ScannerState({required this.mode, required this.pendingSync});

  /// Mode yang sedang aktif di layar.
  final ScanMode mode;

  /// Berapa scan di antrean offline yang belum berhasil dikirim ke server.
  final int pendingSync;

  /// True saat sebuah scan sedang diproses (input harus dikunci).
  bool get isProcessing => this is ScannerProcessing;

  /// True saat layar harus menampilkan antrean offline yang menunggu.
  bool get hasPendingSync => pendingSync > 0;
}

/// Siap menerima scan; belum ada hasil yang ditampilkan.
final class ScannerIdle extends ScannerState {
  const ScannerIdle({required super.mode, required super.pendingSync});
}

/// Sebuah scan sedang dikirim ke server.
final class ScannerProcessing extends ScannerState {
  const ScannerProcessing({
    required super.mode,
    required super.pendingSync,
    required this.ticketCode,
  });

  /// Kode yang sedang diverifikasi (ditampilkan di viewfinder).
  final String ticketCode;
}

/// Server menjawab dengan salah satu dari enam verdict.
///
/// Perhatikan: ini "request berhasil", bukan "tiket valid" — validitas tiket ada
/// di [result] dan bisa berupa ALREADY_USED / EXPIRED / NOT_FOUND / CANCELLED.
final class ScannerSuccess extends ScannerState {
  const ScannerSuccess({
    required super.mode,
    required super.pendingSync,
    required this.result,
  });

  final ScanResult result;
}

/// Koneksi putus: scan disimpan di antrean offline dan akan dikirim saat online.
final class ScannerQueued extends ScannerState {
  const ScannerQueued({
    required super.mode,
    required super.pendingSync,
    required this.ticketCode,
  });

  final String ticketCode;
}

/// Scan gagal dan **tidak** masuk antrean (timeout, 401, 5xx, atau error lain).
final class ScannerError extends ScannerState {
  const ScannerError({
    required super.mode,
    required super.pendingSync,
    required this.message,
    required this.kind,
  });

  /// Pesan siap tampil.
  final String message;

  final ScanFailureKind kind;
}
