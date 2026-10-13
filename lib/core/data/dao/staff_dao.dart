// File: staff_dao.dart
// DAO penyimpanan petugas yang sedang login.

import 'package:hive/hive.dart';

/// Menyimpan identitas petugas yang berhasil login ke Hive.
///
/// Dipakai supaya nama di Profil tetap benar setelah aplikasi dibuka ulang
/// (token masih valid tetapi balikan `/login` sudah tidak ada lagi), dan tetap
/// benar saat perangkat offline. Dibersihkan saat logout supaya petugas
/// berikutnya di perangkat yang sama tidak melihat nama petugas sebelumnya.
///
/// Sengaja tidak ada nilai bawaan: `getStaff()` mengembalikan null bila belum
/// ada yang login.
class StaffDAO {
  static const String _boxName = 'staff_box';
  static const String _staffKey = 'logged_in_staff';

  // Singleton — sama seperti CheckpointDAO.
  static final StaffDAO _instance = StaffDAO._internal();
  factory StaffDAO() => _instance;
  StaffDAO._internal();

  Box<dynamic>? _box;

  bool get isInitialized => _box?.isOpen ?? false;

  Future<Box<dynamic>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox(_boxName);
    return _box!;
  }

  /// Buka box Hive. Dipanggil sekali saat bootstrap aplikasi.
  Future<void> initialize() async {
    try {
      await _getBox();
    } catch (e) {
      throw Exception('Failed to initialize StaffDAO: $e');
    }
  }

  /// Simpan petugas yang sedang login.
  Future<void> saveStaff(Map<String, dynamic> staff) async {
    try {
      final box = await _getBox();
      await box.put(_staffKey, staff);
    } catch (e) {
      throw Exception('Failed to save staff: $e');
    }
  }

  /// Petugas yang tersimpan, atau null bila belum ada yang login.
  Map<String, dynamic>? getStaff() {
    try {
      final box = _box;
      if (box == null || !box.isOpen) return null;

      final data = box.get(_staffKey);
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Hapus data petugas — dipakai saat logout.
  Future<void> clearStaff() async {
    try {
      final box = await _getBox();
      await box.delete(_staffKey);
    } catch (e) {
      throw Exception('Failed to clear staff: $e');
    }
  }

  /// Tutup box Hive.
  Future<void> close() async {
    try {
      final box = _box;
      if (box != null && box.isOpen) {
        await box.close();
      }
      _box = null;
    } catch (e) {
      // diabaikan — sama seperti CheckpointDAO
    }
  }
}
