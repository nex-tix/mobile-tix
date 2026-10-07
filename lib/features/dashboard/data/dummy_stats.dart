import '../../../core/constants/ticket_status.dart';
import 'models/gate_stats.dart';

/// Authored tallies for the dashboard. Figures add up on purpose — the strip sums to
/// the entry count, and the refusal rows sum to the refusal total — because a demo
/// whose numbers contradict each other discredits the whole screen.
class DummyStats {
  const DummyStats._();

  static GateStats forPeriod(StatsPeriod period, {required String gate}) {
    final now = DateTime.now();
    switch (period) {
      case StatsPeriod.today:
        return GateStats(
          entered: 128,
          valid: 121,
          reasons: const {
            TicketStatus.alreadyUsed: 4,
            TicketStatus.expired: 2,
            TicketStatus.notFound: 1,
            TicketStatus.cancelled: 0,
          },
          hourly: const [4, 9, 24, 18, 11, 6, 7, 12, 14, 9, 6, 5, 3],
          hourStart: 8,
          lastScanCode: 'TKT-2026-001245',
          lastScanAt: now.subtract(const Duration(minutes: 3)),
          lastScanStatus: TicketStatus.valid,
          periodNote: 'Shift pagi · 08.00–15.00',
        );
      case StatsPeriod.month:
        return GateStats(
          entered: 3412,
          valid: 3204,
          reasons: const {
            TicketStatus.alreadyUsed: 112,
            TicketStatus.expired: 54,
            TicketStatus.notFound: 29,
            TicketStatus.cancelled: 13,
          },
          hourly: const [4, 8, 21, 16, 10, 6, 6, 11, 12, 8, 6, 4, 2],
          hourStart: 8,
          lastScanCode: 'TKT-2026-001245',
          lastScanAt: now.subtract(const Duration(minutes: 3)),
          lastScanStatus: TicketStatus.valid,
          periodNote:
              '1–${now.day} ${_monthName(now.month)} · rata-rata 114 tiket/hari',
        );
    }
  }

  static String _monthName(int month) {
    const names = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return names[(month - 1).clamp(0, 11)];
  }
}
