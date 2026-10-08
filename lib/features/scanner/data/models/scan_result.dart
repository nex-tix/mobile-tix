// File: scan_result.dart
// Model hasil satu scan tiket — bentuk yang dikembalikan server.

import 'package:flutter/foundation.dart';

import '../../../../core/constants/ticket_status.dart';
import 'scan_mode.dart';
import 'scan_outcome.dart' hide ScanMode;

export 'scan_mode.dart';

/// The result of one ticket scan: what the server answered, plus the context the
/// gate needs to render it.
///
/// Ini model wire — dibangun dari payload API. Lapisan presentasi tetap
/// merender [ScanOutcome]; konversinya lewat [toOutcome] supaya key JSON mentah
/// tidak bocor ke widget.
@immutable
class ScanResult {
  const ScanResult({
    required this.status,
    required this.ticketCode,
    required this.mode,
    required this.scannedAt,
    this.visitorName,
    this.visitorCount = 1,
    this.category,
    this.usedAt,
    this.usedBy,
    this.usedAtCheckpoint,
    this.expiryDate,
    this.message,
  });

  /// One of the five verdicts the gate must handle.
  final TicketStatus status;

  /// The code that was scanned / keyed in.
  final String ticketCode;

  /// The mode the scan was made in — decides which endpoint produced it.
  final ScanMode mode;

  /// When the scan happened on the device (device clock, not server clock).
  final DateTime scannedAt;

  /// Holder of the ticket (not available for NOT_FOUND).
  final String? visitorName;

  /// How many people this ticket admits.
  final int visitorCount;

  /// Ticket category — Individu, Rombongan, VIP…
  final String? category;

  /// For ALREADY_USED: when the ticket was first used.
  final DateTime? usedAt;

  /// For ALREADY_USED: which officer used it.
  final String? usedBy;

  /// For ALREADY_USED: which gate used it.
  final String? usedAtCheckpoint;

  /// For EXPIRED: the last date the ticket would have been valid.
  final DateTime? expiryDate;

  /// Operator-facing note from the server, when it sends one.
  final String? message;

  /// The ticket admits its holder: the only verdict that may open the gate.
  bool get isValid => status == TicketStatus.valid;

  /// A check-in actually wrote the ticket.
  bool get isCheckedIn => mode == ScanMode.checkIn && isValid;

  /// True when the payload carried a holder for the result sheet to show.
  bool get hasHolder => visitorName != null && status != TicketStatus.notFound;

  /// Parse one API payload entry.
  ///
  /// Tolerant of both snake_case (kontrak yang didokumentasikan) and camelCase,
  /// dan of a missing status — payload yang tidak terbaca dianggap
  /// [TicketStatus.notFound] supaya gate tidak pernah merender verdict kosong.
  factory ScanResult.fromJson(
    Map<String, dynamic> json, {
    required ScanMode mode,
    DateTime? scannedAt,
  }) {
    return ScanResult(
      status: parseStatus(json['status']),
      ticketCode: _string(json['ticket_code'] ?? json['ticketCode']) ?? '',
      mode: mode,
      scannedAt: scannedAt ?? DateTime.now(),
      visitorName: _string(json['visitor_name'] ?? json['visitorName']),
      visitorCount: _int(json['visitor_count'] ?? json['visitorCount']) ?? 1,
      category: _string(
        json['category'] ?? json['visitor_type'] ?? json['ticket_type'],
      ),
      usedAt: _date(json['used_at'] ?? json['usedAt'] ?? json['check_in_time']),
      usedBy: _string(
        json['used_by'] ?? json['usedBy'] ?? json['validator_name'],
      ),
      usedAtCheckpoint: _string(
        json['used_at_checkpoint'] ??
            json['usedAtCheckpoint'] ??
            json['checkpoint'],
      ),
      expiryDate: _date(
        json['expiry_date'] ?? json['expiryDate'] ?? json['event_date'],
      ),
      message: _string(json['message']),
    );
  }

  /// Map the server's status string onto the gate's five verdicts.
  static TicketStatus parseStatus(Object? raw) => TicketStatus.parse(raw);

  /// The presentation model the result sheet renders.
  ScanOutcome toOutcome({String? gate}) {
    return ScanOutcome(
      status: status,
      code: ticketCode,
      at: scannedAt,
      mode: mode,
      visitor: visitorName,
      category: category,
      gate: usedAtCheckpoint ?? gate,
      tickets: visitorCount,
      previousUseAt: status == TicketStatus.alreadyUsed ? usedAt : null,
      previousUseGate: status == TicketStatus.alreadyUsed
          ? usedAtCheckpoint
          : null,
      simulated: false,
    );
  }

  @override
  String toString() =>
      'ScanResult(${status.code}, $ticketCode, ${mode.wireValue})';
}

String? _string(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_string(value) ?? '');
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final text = _string(value);
  if (text == null) return null;
  return DateTime.tryParse(text)?.toLocal();
}
