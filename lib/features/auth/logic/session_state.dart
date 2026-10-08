import 'package:flutter/material.dart';

import '../../checkpoint/data/models/checkpoint.dart';
import '../data/models/gate_staff.dart';

/// The gate session: who is signed in and at which checkpoint.
class SessionState extends ChangeNotifier {
  GateStaff? _staff;
  Checkpoint? _checkpoint;
  bool _signingIn = false;

  GateStaff? get staff => _staff;
  Checkpoint? get checkpoint => _checkpoint;
  bool get signingIn => _signingIn;

  /// Signed in (before or after choosing a gate).
  bool get signedIn => _staff != null;

  /// Signed in, no gate chosen yet.
  bool get needsCheckpoint => _staff != null && _checkpoint == null;

  /// Ready to scan.
  bool get ready => _staff != null && _checkpoint != null;

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
    _signingIn = false;
    notifyListeners();
  }

  void selectCheckpoint(Checkpoint checkpoint) {
    _checkpoint = checkpoint;
    notifyListeners();
  }

  void setStaffAndCheckpoint({GateStaff? staff, Checkpoint? checkpoint}) {
    _staff = staff ?? dummyStaff;
    if (checkpoint != null) {
      _checkpoint = checkpoint;
    }
    notifyListeners();
  }

  void signOut() {
    _staff = null;
    _checkpoint = null;
    notifyListeners();
  }
}
