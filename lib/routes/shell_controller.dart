import 'package:flutter/material.dart';

/// Which tab the shell is showing based on `newDesign` (Dashboard, Scan, History).
enum ShellTab { dashboard, scanner, history }

/// Navigation state for the three tabs.
class ShellController extends ChangeNotifier {
  int _index = 0;

  int get index => _index;

  ShellTab get tab => ShellTab.values[_index];

  void go(ShellTab tab) => goIndex(ShellTab.values.indexOf(tab));

  void goIndex(int index) {
    if (index == _index || index < 0 || index >= ShellTab.values.length) return;
    _index = index;
    notifyListeners();
  }
}
