import '../../../core/constants/ticket_status.dart';
import '../../scanner/data/models/scan_outcome.dart';
import 'models/ledger_entry.dart';

/// The gate's log for the prototype, newest first.
///
/// Times are built relative to the moment the app opens, so the day-group headers
/// ("HARI INI", "KEMARIN") are always true, whatever date the demo is run on.
List<LedgerEntry> buildDummyHistory() {
  final now = DateTime.now();
  DateTime ago(int minutes) => now.subtract(Duration(minutes: minutes));
  DateTime onDay(int daysBack, int hour, int minute) => DateTime(
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  ).subtract(Duration(days: daysBack));

  return [
    LedgerEntry(
      code: 'TKT-2026-001245',
      at: ago(3),
      gate: 'Gate 1',
      tickets: 1,
      status: TicketStatus.valid,
      mode: ScanMode.checkIn,
      visitor: 'Rangga Prasetyo',
    ),
    LedgerEntry(
      code: 'TKT-2026-001244',
      at: ago(8),
      gate: 'Gate 1',
      tickets: 2,
      status: TicketStatus.alreadyUsed,
      mode: ScanMode.checkIn,
      visitor: 'Nadia Kusuma',
    ),
    LedgerEntry(
      code: 'TKT-2026-001243',
      at: ago(15),
      gate: 'Gate 1',
      tickets: 1,
      status: TicketStatus.expired,
      mode: ScanMode.check,
    ),
    LedgerEntry(
      code: 'TKT-2026-001242',
      at: ago(23),
      gate: 'Gate 1',
      tickets: 3,
      status: TicketStatus.valid,
      mode: ScanMode.checkIn,
      visitor: 'Sari Melati',
    ),
    LedgerEntry(
      code: 'TKT-2026-001240',
      at: ago(52),
      gate: 'Gate 1',
      tickets: 0,
      status: TicketStatus.notFound,
      mode: ScanMode.checkIn,
    ),
    LedgerEntry(
      code: 'TKT-2026-001236',
      at: onDay(1, 16, 48),
      gate: 'Gate 1',
      tickets: 2,
      status: TicketStatus.valid,
      mode: ScanMode.checkIn,
      visitor: 'Dewi Anggraini',
    ),
    LedgerEntry(
      code: 'TKT-2026-001235',
      at: onDay(1, 16, 12),
      gate: 'Gate 1',
      tickets: 1,
      status: TicketStatus.alreadyUsed,
      mode: ScanMode.check,
    ),
  ];
}
