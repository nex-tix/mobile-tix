import 'package:flutter/foundation.dart';

import '../data/dummy_stats.dart';
import '../data/models/gate_stats.dart';

/// Dashboard UI state: the open period, and the first-load moment per period.
class DashboardState extends ChangeNotifier {
  StatsPeriod _period = StatsPeriod.today;
  bool _loading = false;
  final Set<StatsPeriod> _visited = {};

  StatsPeriod get period => _period;
  bool get loading => _loading;

  GateStats statsFor(String gate) => DummyStats.forPeriod(_period, gate: gate);

  Future<void> select(StatsPeriod period) async {
    if (_period == period && _visited.contains(period)) return;
    _period = period;
    if (_visited.contains(period)) {
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    _visited.add(period);
    _loading = false;
    notifyListeners();
  }

  /// The refresh action: shows the reloading state even when the period is already
  /// in hand, because the operator pressed it to *see* the reload.
  Future<void> reload() async {
    _loading = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    _visited.add(_period);
    _loading = false;
    notifyListeners();
  }
}
