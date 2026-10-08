// File: connectivity_monitor.dart
// Kontrak status koneksi untuk lapisan domain (bukan widget).

/// Sumber tunggal status koneksi aplikasi.
///
/// Lapisan domain butuh tahu *apakah* perangkat online tanpa ikut mengurus
/// sumbernya (plugin, toggle demo, dsb). Karena itu `ScannerCubit` bergantung
/// pada kontrak ini, bukan pada implementasi konkretnya.
abstract class ConnectivityMonitor {
  /// Status koneksi saat ini.
  bool get isOnline;

  /// Emit `true` setiap kali koneksi kembali tersedia, `false` saat putus.
  ///
  /// Broadcast stream — banyak listener boleh berlangganan.
  Stream<bool> get onlineChanges;
}
