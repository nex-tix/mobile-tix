import 'package:flutter/foundation.dart';

import '../../../../core/constants/ticket_status.dart';
import 'scan_mode.dart';

export 'scan_mode.dart';

/// The result of one ticket scan, as the gate renders it.
///
/// Ini model presentasi. Hasil dari server masuk sebagai `ScanResult`
/// (lihat `scan_result.dart`) dan dikonversi lewat `ScanResult.toOutcome()`;
/// `ScanOutcome` langsung boleh dibentuk hanya oleh data demo di layar.
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
    this.actualAdmitted,
    this.previousUseAt,
    this.previousUseGate,
    this.message,
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
  final int? actualAdmitted;

  /// For ALREADY_USED: when and where the ticket was first used.
  final DateTime? previousUseAt;
  final String? previousUseGate;

  /// Operator-facing note from the server for non-valid tickets.
  final String? message;

  /// Marks the record as prototype data on screen.
  final bool simulated;
}
