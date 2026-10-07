import 'package:flutter/foundation.dart';

/// Simulated connectivity for the prototype.
///
/// There is no `connectivity_plus` subscription here and no offline queue: the gate
/// staff's connection state is a demo toggle so the offline UI can be inspected.
class DemoConnectivity extends ChangeNotifier {
  DemoConnectivity({bool? online}) : _online = online ?? true;

  bool _online;
  bool get online => _online;
  bool get offline => !_online;

  void toggle() {
    _online = !_online;
    notifyListeners();
  }

  void setOnline(bool value) {
    if (_online == value) return;
    _online = value;
    notifyListeners();
  }
}
