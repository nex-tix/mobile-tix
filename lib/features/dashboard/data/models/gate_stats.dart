import 'package:flutter/foundation.dart';

import '../../../../core/constants/ticket_status.dart';

enum StatsPeriod {
  today('HARI INI'),
  month('BULAN INI');

  const StatsPeriod(this.label);

  final String label;
}

/// One period's tally for one gate.
///
/// `hourly` is a real series (one bucket per operating hour from [hourStart]), not a
/// decorative squiggle: the supervisor reads it to decide whether to open a second
/// lane, so the strip is drawn from these numbers.
@immutable
class GateStats {
  const GateStats({
    required this.entered,
    required this.valid,
    required this.reasons,
    required this.hourly,
    required this.hourStart,
    this.lastScanCode,
    this.lastScanAt,
    this.lastScanStatus,
    required this.periodNote,
  });

  final int entered;
  final int valid;

  /// Refusals by verdict. Always five keys, zeroes included: a missing row reads as
  /// "not measured" when it means "none".
  final Map<TicketStatus, int> reasons;

  final List<int> hourly;
  final int hourStart;

  final String? lastScanCode;
  final DateTime? lastScanAt;
  final TicketStatus? lastScanStatus;

  /// One line of context under the tally: what the period covers.
  final String periodNote;

  int get refused => reasons.values.fold(0, (a, b) => a + b);

  int get peakIndex {
    var best = 0;
    for (var i = 1; i < hourly.length; i++) {
      if (hourly[i] > hourly[best]) best = i;
    }
    return best;
  }

  int get peakCount => hourly.isEmpty ? 0 : hourly[peakIndex];

  int get peakHour => hourStart + peakIndex;
}
