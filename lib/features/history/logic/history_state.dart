import 'package:flutter/foundation.dart';

import '../../../core/constants/ticket_status.dart';
import '../data/dummy_history.dart';
import '../data/models/ledger_entry.dart';

/// The gate log's UI state: which verdict's rows are shown, and the two loading
/// moments (first open, pull to refresh).
class HistoryState extends ChangeNotifier {
  final List<LedgerEntry> _all = buildDummyHistory();
  TicketStatus? _filter;
  bool _loading = false;
  bool _loadedOnce = false;

  List<LedgerEntry> get all => List.unmodifiable(_all);
  TicketStatus? get filter => _filter;
  bool get loading => _loading;

  List<LedgerEntry> get entries => _filter == null
      ? all
      : _all.where((e) => e.status == _filter).toList(growable: false);

  int get todayCount => _all.length;

  Map<TicketStatus, int> get counts {
    final map = <TicketStatus, int>{};
    for (final status in TicketStatus.values) {
      map[status] = _all.where((e) => e.status == status).length;
    }
    return map;
  }

  void setFilter(TicketStatus? status) {
    if (_filter == status) return;
    _filter = status;
    notifyListeners();
  }

  Future<void> loadOnce() async {
    if (_loadedOnce) return;
    _loading = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    _loadedOnce = true;
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    _loading = false;
    notifyListeners();
  }
}
