import 'models/scan_outcome.dart';
import '../../../core/constants/ticket_status.dart';

/// Simulated scanner.
///
/// The prototype answers from a fixed rule so the same code always produces the same
/// verdict (a demo that returns a random status teaches nothing). A trailing digit
/// selects the outcome; anything else counts as a valid ticket.
class DummyScanner {
  const DummyScanner._();

  static const Map<String, TicketStatus> _byCode = {
    'TKT-2026-001245': TicketStatus.valid,
    'TKT-2026-001244': TicketStatus.alreadyUsed,
    'TKT-2026-001243': TicketStatus.expired,
    'TKT-2026-001242': TicketStatus.valid,
    'TKT-2026-001241': TicketStatus.cancelled,
    'TKT-2026-001240': TicketStatus.notFound,
  };

  static const Map<String, (String, String)> _holders = {
    'TKT-2026-001245': ('Rangga Prasetyo', 'Individu'),
    'TKT-2026-001244': ('Nadia Kusuma', 'Individu'),
    'TKT-2026-001243': ('Bagas Wirawan', 'Rombongan'),
    'TKT-2026-001242': ('Sari Melati', 'Individu'),
  };

  static const List<(String, String)> _fallbackHolders = [
    ('Aditya Nugraha', 'Individu'),
    ('Putri Handayani', 'Individu'),
    ('Yusuf Ramadhan', 'Rombongan'),
    ('Clara Wijaya', 'Individu'),
  ];

  /// The verdict a code produces, without any I/O.
  static TicketStatus statusFor(String code) {
    final normalised = code.trim().toUpperCase();
    final known = _byCode[normalised];
    if (known != null) return known;
    if (normalised.endsWith('4')) return TicketStatus.alreadyUsed;
    if (normalised.endsWith('3')) return TicketStatus.expired;
    if (normalised.endsWith('0') || normalised.endsWith('9')) {
      return TicketStatus.notFound;
    }
    if (normalised.endsWith('1')) return TicketStatus.cancelled;
    return TicketStatus.valid;
  }

  static ScanOutcome scan({
    required String code,
    required ScanMode mode,
    String? gate,
    DateTime? at,
  }) {
    return outcomeFor(
      status: statusFor(code),
      code: code.trim().toUpperCase(),
      mode: mode,
      gate: gate,
      at: at,
    );
  }

  /// Used both by [scan] and by the demo controls that force a single verdict.
  static ScanOutcome outcomeFor({
    required TicketStatus status,
    required String code,
    required ScanMode mode,
    String? gate,
    DateTime? at,
  }) {
    final now = at ?? DateTime.now();
    final holder =
        _holders[code] ??
        _fallbackHolders[code.hashCode.abs() % _fallbackHolders.length];
    final unknown = status == TicketStatus.notFound;

    return ScanOutcome(
      status: status,
      code: code,
      at: now,
      mode: mode,
      gate: unknown ? null : gate ?? 'Gate 1',
      visitor: unknown ? null : holder.$1,
      category: unknown ? null : holder.$2,
      tickets: unknown
          ? 0
          : code.endsWith('2')
          ? 3
          : code.endsWith('4')
          ? 2
          : 1,
      previousUseAt: status == TicketStatus.alreadyUsed
          ? now.subtract(const Duration(minutes: 27))
          : null,
      previousUseGate: status == TicketStatus.alreadyUsed ? 'Gate 1' : null,
    );
  }

  /// A ready-made outcome for each verdict, for the "uji tampilan" controls.
  static ScanOutcome demo(TicketStatus status, ScanMode mode) {
    const samples = {
      TicketStatus.valid: 'TKT-2026-001245',
      TicketStatus.alreadyUsed: 'TKT-2026-001244',
      TicketStatus.expired: 'TKT-2026-001243',
      TicketStatus.notFound: 'TKT-2026-001240',
      TicketStatus.cancelled: 'TKT-2026-001241',
    };
    return outcomeFor(
      status: status,
      code: samples[status]!,
      mode: mode,
      gate: 'Gate 1',
    );
  }
}
