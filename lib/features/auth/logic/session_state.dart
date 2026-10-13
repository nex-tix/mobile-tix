import 'package:flutter/material.dart';

import '../../../core/data/dao/checkpoint_dao.dart';
import '../../../core/data/dao/staff_dao.dart';
import '../../checkpoint/data/models/checkpoint.dart';
import '../data/models/gate_staff.dart';

/// The gate session: who is signed in and at which checkpoint.
class SessionState extends ChangeNotifier {
  final CheckpointDAO _checkpointDao = CheckpointDAO();
  final StaffDAO _staffDao = StaffDAO();

  GateStaff? _staff;
  Checkpoint? _checkpoint;

  SessionState() {
    restoreFromDao();
  }

  /// Petugas yang sedang login.
  ///
  /// Dibaca dari memori bila login terjadi di sesi ini; kalau aplikasi baru
  /// dibuka ulang (token masih ada) nilainya diambil dari penyimpanan supaya
  /// nama di Profil tidak berubah menjadi nama bawaan.
  GateStaff? get staff {
    final inMemory = _staff;
    if (inMemory != null) return inMemory;

    final cached = _staffDao.getStaff();
    return cached == null ? null : GateStaff.fromJson(cached);
  }

  Checkpoint? get checkpoint => _checkpoint;

  /// Signed in (before or after choosing a gate).
  bool get signedIn => staff != null;

  /// Signed in, no gate chosen yet.
  bool get needsCheckpoint => staff != null && _checkpoint == null;

  /// Ready to scan.
  bool get ready => staff != null && _checkpoint != null;

  /// Pulihkan petugas & gate aktif dari penyimpanan.
  void restoreFromDao() {
    try {
      final cachedStaff = _staffDao.getStaff();
      final cachedCheckpoint = _checkpointDao.getActiveCheckpoint();
      if (cachedStaff != null) {
        _staff = GateStaff.fromJson(cachedStaff);
      }
      if (cachedCheckpoint != null) {
        _checkpoint = Checkpoint.fromJson(cachedCheckpoint);
      }
      if (cachedStaff != null || cachedCheckpoint != null) {
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> selectCheckpoint(Checkpoint checkpoint) async {
    _checkpoint = checkpoint;
    notifyListeners();
    await _checkpointDao.saveCheckpoint(checkpoint.toJson());
  }

  Future<void> setStaffAndCheckpoint({GateStaff? staff, Checkpoint? checkpoint}) async {
    // Tanpa nilai bawaan: kalau server belum memberi data petugas, biarkan
    // kosong sampai login benar-benar mengisinya.
    if (staff != null) {
      _staff = staff;
      await _staffDao.saveStaff(staff.toJson());
    }
    if (checkpoint != null) {
      _checkpoint = checkpoint;
      await _checkpointDao.saveCheckpoint(checkpoint.toJson());
    } else if (_checkpoint == null) {
      restoreFromDao();
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    _staff = null;
    _checkpoint = null;
    notifyListeners();
    // Petugas berikutnya di perangkat ini tidak boleh melihat nama sebelumnya.
    await _staffDao.clearStaff();
    await _checkpointDao.clearActiveCheckpoint();
  }
}
