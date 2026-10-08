import 'package:flutter/material.dart';
import 'package:mobile_tix/core/constants/app_icons.dart';

import '../../../../core/utils/formatters.dart';
import '../../data/models/scan_record.dart';

/// Ticket card matching Screen 13 (`13._history_all/code.html`).
///
/// Merender satu baris riwayat dari server. Yang dipakai hanya kejadian yang
/// sudah tercatat — tidak ada tanggal atau jam yang dikarang di sini.
class HistoryRow extends StatelessWidget {
  const HistoryRow({super.key, required this.record});

  final ScanRecord record;

  @override
  Widget build(BuildContext context) {
    final isValid = record.isValid;

    final badgeOuterColor = isValid
        ? const Color(0x332ECC71)
        : const Color(0x33CF4647);
    final badgeInnerColor = isValid
        ? const Color(0xFF2ECC71)
        : const Color(0xFFCF4647);
    final badgeIcon = isValid ? AppIcons.check : AppIcons.close;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetail(context, record),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF212B2F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF3E4E55)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Icon Badge & Ticket Info
                Row(
                  children: [
                    // Outer Ring Badge
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: badgeOuterColor,
                        border: Border.all(
                          color: badgeInnerColor.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: badgeInnerColor,
                          ),
                          child: Icon(badgeIcon, size: 15, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Ticket Serial Code & Time
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.ticketCode,
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF8F6F6),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          Fmt.clockSeconds(record.scannedAt),
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 12,
                            color: Color(0xFFA3B1B7),
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
                      '${record.visitorCount} visitor',
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFF8F6F6),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      record.checkpoint ?? '—',
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        color: Color(0xFFA3B1B7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _showDetail(BuildContext context, ScanRecord record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF212B2F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Color(0xFF3E4E55), width: 1.2)),
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
                      color: const Color(0xFF4B5E66),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Text(
                  'Detail Tiket ${record.ticketCode}',
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF8F6F6),
                  ),
                ),
                const SizedBox(height: 16),
                _infoRow(
                  'Status',
                  record.status.label,
                  record.isValid
                      ? const Color(0xFF2ECC71)
                      : const Color(0xFFCF4647),
                ),
                _infoRow(
                  'Waktu Pindai',
                  '${Fmt.fullDate(record.scannedAt)} ${Fmt.clockSeconds(record.scannedAt)}',
                  const Color(0xFFF8F6F6),
                ),
                _infoRow(
                  'Checkpoint',
                  record.checkpoint ?? '—',
                  const Color(0xFFF8F6F6),
                ),
                _infoRow(
                  'Jumlah Pengunjung',
                  '${record.visitorCount} orang',
                  const Color(0xFFF8F6F6),
                ),
                if (record.category != null)
                  _infoRow(
                    'Jenis Tiket',
                    record.category!,
                    const Color(0xFFF8F6F6),
                  ),
                if (record.validatedBy != null)
                  _infoRow(
                    'Petugas',
                    record.validatedBy!,
                    const Color(0xFFF8F6F6),
                  ),
                if (record.visitorName != null)
                  _infoRow(
                    'Nama Tamu',
                    record.visitorName!,
                    const Color(0xFFF5D061),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _infoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFFA3B1B7)),
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
