import 'package:flutter/material.dart';

import '../../../core/data/dao/checkpoint_dao.dart';
import '../../checkpoint/data/models/checkpoint.dart';
import '../data/models/gate_staff.dart';

/// The gate session: who is signed in and at which checkpoint.
class SessionState extends ChangeNotifier {
  final CheckpointDAO _checkpointDao = CheckpointDAO();

  GateStaff? _staff;
  Checkpoint? _checkpoint;
  bool _signingIn = false;

  SessionState() {
    restoreFromDao();
  }

  GateStaff? get staff => _staff;
  Checkpoint? get checkpoint => _checkpoint;
  bool get signingIn => _signingIn;

  /// Signed in (before or after choosing a gate).
  bool get signedIn => _staff != null;

  /// Signed in, no gate chosen yet.
  bool get needsCheckpoint => _staff != null && _checkpoint == null;

  /// Ready to scan.
  bool get ready => _staff != null && _checkpoint != null;

  /// Restore active checkpoint from persistent storage.
  void restoreFromDao() {
    try {
      final cached = _checkpointDao.getActiveCheckpoint();
      if (cached != null) {
        _checkpoint = Checkpoint.fromJson(cached);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> signIn({
    required String username,
    required String password,
    required Checkpoint checkpoint,
  }) async {
    _signingIn = true;
    notifyListeners();
    // Simulated round trip — no request is made.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    _staff = dummyStaff;
    _checkpoint = checkpoint;
    await _checkpointDao.saveCheckpoint(checkpoint.toJson());
    _signingIn = false;
    notifyListeners();
  }

  Future<void> selectCheckpoint(Checkpoint checkpoint) async {
    _checkpoint = checkpoint;
    notifyListeners();
    await _checkpointDao.saveCheckpoint(checkpoint.toJson());
  }

  Future<void> setStaffAndCheckpoint({GateStaff? staff, Checkpoint? checkpoint}) async {
    _staff = staff ?? dummyStaff;
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
    await _checkpointDao.clearActiveCheckpoint();
  }
}
