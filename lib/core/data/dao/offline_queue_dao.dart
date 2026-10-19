// File: offline_queue_dao.dart
// DAO untuk antrean scan offline (typed, berbasis Hive adapter QueuedScan)

import 'package:hive/hive.dart';

import '../../../features/scanner/data/models/queued_scan.dart';

/// Offline Queue DAO — menyimpan hasil scan saat perangkat tidak punya koneksi.
///
/// Fitur:
/// - Satu item = satu entry Hive (key = [QueuedScan.id]), jadi enqueue/remove
///   bersifat O(1) — tidak menulis ulang seluruh antrean tiap kali.
/// - Urutan FIFO: diurutkan berdasarkan [QueuedScan.queuedAt].
/// - TTL 24 jam: item yang lebih tua otomatis dibuang saat antrean dibaca,
///   supaya scan basi tidak ikut terkirim ke server.
/// - Singleton pattern, sama seperti DAO lain di aplikasi.
class OfflineQueueDAO {
  // Nama box Hive untuk queue
  static const String _boxName = 'offline_queue_box';

  // TTL item antrean: 24 jam. Lewat dari ini, item dianggap tidak relevan.
  static const Duration _queueTtl = Duration(hours: 24);

  // Singleton instance
  static final OfflineQueueDAO _instance = OfflineQueueDAO._internal();
  factory OfflineQueueDAO() => _instance;
  OfflineQueueDAO._internal();

  // Reference ke Hive box bertipe QueuedScan
  Box<QueuedScan>? _queueBox;

  // O(1) lookup untuk ticketCode → Set<String> kode tiket aktif di antrean.
  // Diisi saat getAll() / initialize, di-maintain saat enqueue/remove/clear.
  final Set<String> _ticketCodeIndex = <String>{};

  // Stempel waktu terakhir yang sudah dipakai untuk sebuah item antrean.
  // Dipakai penjaga monotonik di [_monotonicStamp].
  DateTime _lastStamp = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  bool get isInitialized => _queueBox?.isOpen ?? false;

  /// Daftarkan Hive adapter untuk [QueuedScan].
  ///
  /// Panggil 1x sebelum box dibuka — di main() untuk aplikasi, dan di setUpAll
  /// untuk unit test. Aman dipanggil berkali-kali karena dicek dulu.
  static void registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(QueuedScanAdapter());
    }
  }

  /// Helper untuk memastikan box sudah terbuka
  Future<Box<QueuedScan>> _getBox() async {
    if (_queueBox != null && _queueBox!.isOpen) {
      return _queueBox!;
    }
    registerAdapters();
    _queueBox = await Hive.openBox<QueuedScan>(_boxName);
    return _queueBox!;
  }

  /// Initialize DAO — buka Hive box untuk antrean offline
  ///
  /// Throws: Exception jika gagal buka box
  Future<void> initialize() async {
    try {
      await _getBox();
      // Bangun index O(1) dari item yang valid (belum expired).
      _rebuildIndex();
    } catch (e) {
      throw Exception('Failed to initialize OfflineQueueDAO: $e');
    }
  }

  void _rebuildIndex() {
    _ticketCodeIndex.clear();
    final box = _queueBox;
    if (box == null || !box.isOpen) return;
    final now = DateTime.now().toUtc();
    for (final key in box.keys) {
      final scan = box.get(key);
      if (scan != null && scan.ageFrom(now) <= _queueTtl) {
        _ticketCodeIndex.add(scan.ticketCode);
      }
    }
  }

  /// Cek apakah tiket dengan kode ini sudah ada di antrean aktif (belum kedaluwarsa).
  bool containsTicket(String ticketCode) {
    final code = ticketCode.trim();
    if (code.isEmpty) return false;
    return _ticketCodeIndex.contains(code);
  }

  /// Masukkan satu scan ke antrean offline.
  ///
  /// Mencegah duplikasi: jika tiket sudah ada di antrean aktif, tidak dibuat
  /// item baru untuk mencegah multi check-in saat online kembali.
  ///
  /// [ticketCode]: barcode/QR hasil scan
  /// [checkpointId]: gate tempat scan dilakukan
  /// [mode]: `check` atau `checkIn`
  /// Returns: objek [QueuedScan] yang tersimpan
  Future<QueuedScan> enqueue({
    required String ticketCode,
    required String checkpointId,
    String mode = 'checkIn',
    int? actualVisitorCount,
  }) async {
    try {
      final code = ticketCode.trim();
      final box = await _getBox();

      // Cegah duplikasi via index O(1)
      if (_ticketCodeIndex.contains(code)) {
        final existing = getAll().cast<QueuedScan?>().firstWhere(
          (scan) => scan?.ticketCode == code,
          orElse: () => null,
        );
        if (existing != null) return existing;
      }

      // Waktu scan (UTC) — dipakai sebagai urutan FIFO dan dasar TTL
      final stamp = _monotonicStamp(DateTime.now().toUtc());
      final scan = QueuedScan(
        id: 'offline_${stamp.microsecondsSinceEpoch}',
        ticketCode: code,
        mode: mode,
        checkpointId: checkpointId,
        queuedAt: stamp,
        actualVisitorCount: actualVisitorCount,
      );

      // Simpan per-item (key = id) — tidak menulis ulang seluruh antrean
      await box.put(scan.id, scan);
      _ticketCodeIndex.add(code);
      return scan;
    } catch (e) {
      throw Exception('Failed to enqueue scan: $e');
    }
  }

  /// Stempel waktu yang **selalu naik** untuk setiap item antrean baru.
  ///
  /// Jam perangkat (khususnya di Windows) punya resolusi kasar: dua scan
  /// beruntun dapat memperoleh microsecond yang persis sama. Karena ID item
  /// diturunkan dari stempel ini, tabrakan berarti `box.put` kedua menimpa yang
  /// pertama — satu check-in hilang tanpa jejak. Urutan naik ini menjaga ID
  /// tetap unik sekaligus menjamin FIFO, karena [getAll] mengurutkan menurut
  /// [QueuedScan.queuedAt].
  DateTime _monotonicStamp(DateTime now) {
    if (now.isAfter(_lastStamp)) {
      _lastStamp = now;
    } else {
      _lastStamp = _lastStamp.add(const Duration(microseconds: 1));
    }
    return _lastStamp;
  }

  /// Simpan objek [QueuedScan] yang sudah dibentuk pemanggil.
  ///
  /// Berguna untuk restore dari backup atau pengujian.
  Future<void> save(QueuedScan scan) async {
    try {
      final box = await _getBox();
      await box.put(scan.id, scan);
    } catch (e) {
      throw Exception('Failed to save queued scan: $e');
    }
  }

  /// Ambil semua item antrean yang belum kedaluwarsa (urutan FIFO).
  ///
  /// Item berumur > 24 jam dihapus otomatis dan tidak ikut dikembalikan,
  /// sehingga sync berikutnya tidak mengirim data basi.
  List<QueuedScan> getAll() {
    try {
      final box = _queueBox;
      if (box == null || !box.isOpen) return [];

      final now = DateTime.now().toUtc();

      // Pisahkan item valid dan item kedaluwarsa dalam sekali iterasi
      final valid = <QueuedScan>[];
      final expiredKeys = <dynamic>[];

      for (final key in box.keys) {
        final scan = box.get(key);
        if (scan == null) {
          expiredKeys.add(key); // entry korup → buang
          continue;
        }
        if (scan.ageFrom(now) > _queueTtl) {
          expiredKeys.add(key);
        } else {
          valid.add(scan);
        }
      }

      // Bersihkan item kedaluwarsa + index-nya
      if (expiredKeys.isNotEmpty) {
        for (final key in expiredKeys) {
          final scan = box.get(key);
          if (scan != null) _ticketCodeIndex.remove(scan.ticketCode);
        }
        box.deleteAll(expiredKeys);
      }

      // Sort ascending — yang paling lama di-queue dikirim lebih dulu
      valid.sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
      return valid;
    } catch (e) {
      return [];
    }
  }

  /// Item pertama yang harus dikirim saat sync (paling lama, belum expired).
  QueuedScan? first() {
    final items = getAll();
    return items.isEmpty ? null : items.first;
  }

  /// Hapus satu item antrean setelah berhasil dikirim ke server.
  Future<void> remove(String id) async {
    try {
      final box = await _getBox();
      final scan = box.get(id);
      if (scan != null) _ticketCodeIndex.remove(scan.ticketCode);
      await box.delete(id);
    } catch (e) {
      throw Exception('Failed to remove queued scan: $e');
    }
  }

  /// Naikkan counter percobaan kirim untuk satu item.
  ///
  /// Dipakai saat sync gagal berulang supaya item bisa diprioritaskan
  /// atau dilewati pada percobaan berikutnya.
  Future<void> incrementRetry(String id) async {
    try {
      final box = await _getBox();
      final scan = box.get(id);
      if (scan == null) return;

      // Mutasi lalu simpan ulang entry yang sama
      scan.retryCount = scan.retryCount + 1;
      await box.put(id, scan);
    } catch (e) {
      throw Exception('Failed to increment retry count: $e');
    }
  }

  /// Hapus seluruh isi antrean (dipakai saat logout / reset perangkat).
  Future<void> clear() async {
    try {
      final box = await _getBox();
      _ticketCodeIndex.clear();
      await box.clear();
    } catch (e) {
      throw Exception('Failed to clear offline queue: $e');
    }
  }

  /// Jumlah item valid (belum expired) di antrean.
  int get size => getAll().length;

  /// True jika masih ada item menunggu dikirim.
  bool get hasItems => size > 0;

  /// Tutup Hive box — bersihkan resource.
  Future<void> close() async {
    try {
      final box = _queueBox;
      if (box == null) return;
      await box.close();
      _queueBox = null;
    } catch (e) {
      // ignore
    }
  }
}
