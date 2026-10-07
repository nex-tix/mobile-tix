import 'package:flutter/material.dart';

import '../../checkpoint/data/models/checkpoint.dart';
import '../data/models/gate_staff.dart';

/// Appearance choice, mirrored into [ThemeMode].
enum AppThemeChoice {
  system('Sistem', 'Ikuti pengaturan perangkat'),
  light('Terang', 'Untuk pemakaian siang di luar'),
  dark('Gelap', 'Untuk shift malam dan area redup');

  const AppThemeChoice(this.label, this.note);

  final String label;
  final String note;
}

/// The gate session: who is signed in, at which checkpoint, and the two preferences
/// that change how the app behaves on shift.
///
/// Sign-in is simulated. There is no token, no storage write, and no API call — the
/// Dio layer is untouched; this state machine exists so the three phases of the app
/// (login → pick a gate → work) can be walked through on screen.
class SessionState extends ChangeNotifier {
  GateStaff? _staff;
  Checkpoint? _checkpoint;
  AppThemeChoice _theme = AppThemeChoice.dark;
  bool _sound = true;
  bool _signingIn = false;
  bool _switchingCheckpoint = false;

  GateStaff? get staff => _staff;
  Checkpoint? get checkpoint => _checkpoint;
  AppThemeChoice get themeChoice => _theme;
  bool get soundEnabled => _sound;
  bool get signingIn => _signingIn;
  bool get switchingCheckpoint => _switchingCheckpoint;

  /// Signed in (before or after choosing a gate).
  bool get signedIn => _staff != null;

  /// Signed in, no gate chosen yet.
  bool get needsCheckpoint => _staff != null && _checkpoint == null;

  /// Ready to scan.
  bool get ready => _staff != null && _checkpoint != null;

  ThemeMode get themeMode => switch (_theme) {
    AppThemeChoice.system => ThemeMode.system,
    AppThemeChoice.light => ThemeMode.light,
    AppThemeChoice.dark => ThemeMode.dark,
  };

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
    _switchingCheckpoint = false;
    notifyListeners();
  }

  /// Opened from the profile: the shell stays mounted behind the gate picker.
  void beginCheckpointSwitch() {
    _switchingCheckpoint = true;
    notifyListeners();
  }

  void cancelCheckpointSwitch() {
    _switchingCheckpoint = false;
    notifyListeners();
  }

  void signOut() {
    _staff = null;
    _checkpoint = null;
    _switchingCheckpoint = false;
    if (_checkpoint == null && _staff == null) _theme = _theme;
    notifyListeners();
  }

  void setTheme(AppThemeChoice choice) {
    _theme = choice;
    notifyListeners();
  }

  void setSound(bool value) {
    _sound = value;
    notifyListeners();
  }
}
