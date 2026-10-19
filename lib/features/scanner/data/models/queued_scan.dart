// File: queued_scan.dart
// Model satu item antrean scan offline (belum terkirim ke server saat offline)

import 'package:hive/hive.dart';

// Generated adapter dari hive_generator (jalankan: fvm flutter pub run build_runner build)
part 'queued_scan.g.dart';

/// Satu permintaan scan/check-in yang di-antre karena perangkat offline.
///
/// Alur pakai:
/// 1. Petugas scan tiket saat jaringan mati → [OfflineQueueDAO.enqueue] menyimpan
///    objek ini ke Hive supaya hasil scan tidak hilang.
/// 2. Saat koneksi pulih, antrean dikirim satu per satu; item yang sukses
///    dihapus lewat [OfflineQueueDAO.remove].
///
/// Semua field immutable kecuali [retryCount] yang naik tiap percobaan kirim —
/// dijaga sebagai satu-satunya state yang berubah supaya objek aman dipakai ulang.
@HiveType(typeId: 0)
class QueuedScan {
  /// ID unik item antrean (timestamp-based, dipakai untuk hapus/update).
  @HiveField(0)
  final String id;

  /// Kode tiket dari barcode/QR yang di-scan.
  @HiveField(1)
  final String ticketCode;

  /// Mode scan: `check` (hanya periksa) atau `checkIn` (validasi + check-in).
  @HiveField(2)
  final String mode;

  /// ID gate tempat scan dilakukan (checkpoint aktif petugas).
  @HiveField(3)
  final String checkpointId;

  /// Waktu scan terjadi di perangkat (UTC).
  /// Dipakai untuk TTL 24 jam + urutan FIFO.
  @HiveField(4)
  final DateTime queuedAt;

  /// Berapa kali item ini sudah dicoba dikirim. Mutable agar bisa di-update
  /// tanpa membuat objek baru di Hive.
  @HiveField(5)
  int retryCount;

  /// Jumlah riil pengunjung yang hadir (konfirmasi headcount untuk tiket rombongan).
  @HiveField(6)
  final int? actualVisitorCount;

  /// Constructor
  QueuedScan({
    required this.id,
    required this.ticketCode,
    required this.mode,
    required this.checkpointId,
    required this.queuedAt,
    this.retryCount = 0,
    this.actualVisitorCount,
  });

  /// Umur item antrean sejak di-queue (dipakai untuk cek TTL 24 jam).
  Duration ageFrom(DateTime now) => now.difference(queuedAt);

  /// Payload yang dikirim ke API saat sync.
  /// Mode `checkIn` ke /ticket/validate-and-checkin; `check` ke /ticket/check.
  Map<String, dynamic> toPayload() => {
    'ticketCode': ticketCode,
    'checkpointId': checkpointId,
    'mode': mode,
    'scannedAt': queuedAt.toUtc().toIso8601String(),
    if (actualVisitorCount != null) 'actualVisitorCount': actualVisitorCount,
  };

  @override
  String toString() =>
      'QueuedScan(id: $id, code: $ticketCode, mode: $mode, count: $actualVisitorCount, retry: $retryCount)';
}

