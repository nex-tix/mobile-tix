import 'package:flutter/foundation.dart';

import '../../../../core/constants/ticket_status.dart';

/// What the operator is doing at the gate.
enum ScanMode {
  /// First entry — the scan writes the ticket.
  checkIn('CHECK-IN', 'Masuk'),

  /// Read-only check, typically at the exit.
  check('CEK', 'Cek');

  const ScanMode(this.label, this.shortLabel);

  final String label;
  final String shortLabel;
}

/// The result of one ticket scan. Every field here is dummy data authored for the
/// prototype; nothing arrives from a server in this stage.
@immutable
class ScanOutcome {
  const ScanOutcome({
    required this.status,
    required this.code,
    required this.at,
    required this.mode,
    this.visitor,
    this.category,
    this.gate,
    this.tickets = 1,
    this.previousUseAt,
    this.previousUseGate,
    this.simulated = true,
  });

  final TicketStatus status;
  final String code;
  final DateTime at;
  final ScanMode mode;

  final String? visitor;
  final String? category;
  final String? gate;
  final int tickets;

  /// For ALREADY_USED: when and where the ticket was first used.
  final DateTime? previousUseAt;
  final String? previousUseGate;

  /// Marks the record as prototype data on screen.
  final bool simulated;
}
