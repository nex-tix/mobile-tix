import 'package:flutter/foundation.dart';

import '../../../core/constants/ticket_status.dart';
import '../data/dummy_scans.dart';
import '../data/models/scan_outcome.dart';

/// UI state of the scanner screen.
///
/// The scan itself is simulated: [scan] waits, then asks [DummyScanner] for the
/// verdict that code produces. No camera is opened and no request is sent — the
/// scaffold for the real thing is untouched.
class ScannerState extends ChangeNotifier {
  ScanMode _mode = ScanMode.checkIn;
  bool _processing = false;
  ScanOutcome? _last;
  String? _lastCode;
  bool _cameraBlocked = false;

  ScanMode get mode => _mode;
  bool get processing => _processing;
  ScanOutcome? get last => _last;
  String? get lastCode => _lastCode;

  /// Simulated camera-permission refusal, so the permission wall can be reviewed.
  bool get cameraBlocked => _cameraBlocked;

  void setMode(ScanMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  void toggleCameraBlocked() {
    _cameraBlocked = !_cameraBlocked;
    notifyListeners();
  }

  Future<ScanOutcome> scan({required String code, String? gate}) async {
    _processing = true;
    _lastCode = code;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 850));
    final outcome = DummyScanner.scan(code: code, mode: _mode, gate: gate);
    _processing = false;
    _last = outcome;
    notifyListeners();
    return outcome;
  }

  /// Forces one verdict, for the demo controls that prove every state is designed.
  ScanOutcome showStatus(TicketStatus status) {
    final outcome = DummyScanner.demo(status, _mode);
    _last = outcome;
    _lastCode = outcome.code;
    notifyListeners();
    return outcome;
  }
}
