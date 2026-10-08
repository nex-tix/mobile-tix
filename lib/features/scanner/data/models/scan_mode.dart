// File: scan_mode.dart
// Mode kerja petugas di gate.

/// Apa yang sedang dilakukan operator di gate.
///
/// Mode menentukan endpoint mana yang dipanggil: [checkIn] menulis tiket
/// (destructive, `POST /ticket/validate-and-checkin`), [check] hanya membaca
/// (non-destructive, `POST /ticket/check`). Karena itu mode ikut disimpan di
/// antrean offline — replay sebuah scan harus memakai mode aslinya.
enum ScanMode {
  /// Entri pertama — scan menulis tiket.
  checkIn('CHECK-IN', 'Masuk', 'checkIn'),

  /// Cek baca-saja, biasanya di pintu keluar.
  check('CEK', 'Cek', 'check');

  const ScanMode(this.label, this.shortLabel, this.wireValue);

  final String label;
  final String shortLabel;

  /// Nilai textual yang dikirim ke API dan disimpan di antrean offline.
  final String wireValue;

  /// Kebalikan dari [wireValue]; nilai asing dianggap [checkIn] karena itu mode
  /// default gate.
  static ScanMode fromWire(String? value) {
    for (final mode in ScanMode.values) {
      if (mode.wireValue == value) return mode;
    }
    return ScanMode.checkIn;
  }
}
