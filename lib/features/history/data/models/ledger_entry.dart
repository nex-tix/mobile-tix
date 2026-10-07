import 'package:flutter/foundation.dart';
import 'package:mobile_tix/features/scanner/data/models/scan_outcome.dart';

import '../../../../core/constants/ticket_status.dart';

/// One line of the gate's log. Immutable: the log is a record, not a working set.
@immutable
class LedgerEntry {
  const LedgerEntry({
    required this.code,
    required this.at,
    required this.gate,
    required this.tickets,
    required this.status,
    required this.mode,
    this.visitor,
  });

  final String code;
  final DateTime at;
  final String gate;
  final int tickets;
  final TicketStatus status;
  final ScanMode mode;
  final String? visitor;
}
