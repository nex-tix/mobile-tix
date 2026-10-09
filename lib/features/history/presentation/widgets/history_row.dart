import 'package:flutter/material.dart';
import 'package:mobile_tix/core/constants/app_icons.dart';

import '../../../../core/constants/ticket_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/i18n_helper.dart';
import '../../data/models/scan_record.dart';

/// Ticket card matching Screen 13 (`13._history_all/code.html`).
///
/// Merender satu baris riwayat dari server. Yang dipakai hanya kejadian yang
/// sudah tercatat — tidak ada tanggal atau jam yang dikarang di sini.
class HistoryRow extends StatelessWidget {
  const HistoryRow({super.key, required this.record});

  final ScanRecord record;

  static String _statusText(BuildContext context, TicketStatus status) =>
      switch (status) {
        TicketStatus.valid => context.trSafe('ticket.valid', 'VALID'),
        TicketStatus.alreadyUsed => context.trSafe(
          'ticket.alreadyUsed',
          'SUDAH DIPAKAI',
        ),
        TicketStatus.expired => context.trSafe('ticket.expired', 'KEDALUWARSA'),
        TicketStatus.notFound => context.trSafe(
          'ticket.invalid',
          'TIKET TIDAK VALID',
        ),
        TicketStatus.cancelled => context.trSafe(
          'ticket.cancelled',
          'DIBATALKAN',
        ),
      };

  @override
  Widget build(BuildContext context) {
    final isValid = record.isValid;

    final badgeColor = isValid ? context.colors.valid : context.colors.used;
    final badgeIcon = isValid ? AppIcons.check : AppIcons.close;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDetail(context, record),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.colors.outline)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Icon Badge & Ticket Info
              Row(
                children: [
                  // Satu disc status — tanpa ring bertingkat.
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: badgeColor,
                    ),
                    child: Icon(badgeIcon, size: 17, color: Colors.white),
                  ),
                  const SizedBox(width: 14),

                  // Ticket Serial Code & Time
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.ticketCode,
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: context.colors.ink,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        Fmt.clockSeconds(record.scannedAt),
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 12,
                          color: context.colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Right: Meta details (Visitor count & Gate)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    context.trSafe(
                      'ticket.visitor',
                      '${record.visitorCount} visitor',
                      namedArgs: {'count': '${record.visitorCount}'},
                    ),
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: context.colors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    record.checkpoint ?? '—',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      color: context.colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showDetail(BuildContext context, ScanRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSheet),
            ),
            border: Border(top: BorderSide(color: context.colors.outline)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: context.colors.outline,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Text(
                  context.trSafe(
                    'ticket.detailTitle',
                    'Detail Tiket ${record.ticketCode}',
                    namedArgs: {'code': record.ticketCode},
                  ),
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.colors.ink,
                  ),
                ),
                const SizedBox(height: 16),
                _infoRow(
                  context,
                  context.trSafe('ticket.statusLabel', 'Status'),
                  _statusText(context, record.status),
                  record.status.ink(context.colors),
                ),
                _infoRow(
                  context,
                  context.trSafe('ticket.scanTimeLabel', 'Waktu Pindai'),
                  '${Fmt.fullDate(record.scannedAt)} ${Fmt.clockSeconds(record.scannedAt)}',
                  context.colors.ink,
                ),
                _infoRow(
                  context,
                  context.trSafe('ticket.checkpointLabel', 'Checkpoint'),
                  record.checkpoint ?? '—',
                  context.colors.ink,
                ),
                _infoRow(
                  context,
                  context.trSafe(
                    'ticket.visitorsCountLabel',
                    'Jumlah Pengunjung',
                  ),
                  context.trSafe(
                    'ticket.visitor',
                    '${record.visitorCount} visitor',
                    namedArgs: {'count': '${record.visitorCount}'},
                  ),
                  context.colors.ink,
                ),
                if (record.category != null)
                  _infoRow(
                    context,
                    context.trSafe('ticket.ticketTypeLabel', 'Jenis Tiket'),
                    record.category!,
                    context.colors.ink,
                  ),
                if (record.validatedBy != null)
                  _infoRow(
                    context,
                    context.trSafe('ticket.officerLabel', 'Petugas'),
                    record.validatedBy!,
                    context.colors.ink,
                  ),
                if (record.visitorName != null)
                  _infoRow(
                    context,
                    context.trSafe('ticket.guestNameLabel', 'Nama Tamu'),
                    record.visitorName!,
                    context.colors.ink,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _infoRow(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13.5, color: context.colors.inkMuted),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
