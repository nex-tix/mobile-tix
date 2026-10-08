import 'dart:async';

import 'package:flutter/foundation.dart';

import 'connectivity_monitor.dart';

/// Simulated connectivity for the prototype.
///
/// The app's single source of truth for "are we online": the gate staff's
/// connection state is a demo toggle so the offline UI can be inspected, and the
/// same signal drives the offline scan queue (`ScannerCubit` listens to
/// [onlineChanges]) so the queue can never disagree with the badge on screen.
class DemoConnectivity extends ChangeNotifier implements ConnectivityMonitor {
  DemoConnectivity({bool? online}) : _online = online ?? true;

  bool _online;

  /// Broadcast supaya beberapa listener (UI + cubit) bisa berlangganan sekaligus.
  final StreamController<bool> _changes = StreamController<bool>.broadcast();

  bool get online => _online;
  bool get offline => !_online;

  @override
  bool get isOnline => _online;

  @override
  Stream<bool> get onlineChanges => _changes.stream;

  void toggle() => setOnline(!_online);

  void setOnline(bool value) {
    if (_online == value) return;
    _online = value;
    _changes.add(_online);
    notifyListeners();
  }

  @override
  void dispose() {
    _changes.close();
    super.dispose();
  }
}
