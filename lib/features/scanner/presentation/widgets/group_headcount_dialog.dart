// File: group_headcount_dialog.dart
// Modal konfirmasi jumlah riil pengunjung hadir sebelum check-in tiket rombongan.

import 'package:flutter/material.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/i18n_helper.dart';
import '../../data/models/scan_result.dart';

/// Dialog konfirmasi jumlah fisik pengunjung yang hadir saat scan tiket rombongan.
///
/// Bertujuan memastikan data riil pengunjung dicatat ke server (misal beli 10, hadir 8),
/// dan mencegah pembakaran tiket di database jika proses dibatalkan oleh operator.
class GroupHeadcountDialog extends StatefulWidget {
  const GroupHeadcountDialog({
    super.key,
    required this.scanResult,
    this.isOffline = false,
    required this.onConfirm,
    required this.onCancel,
  });

  final ScanResult scanResult;
  final bool isOffline;
  final ValueChanged<int> onConfirm;
  final VoidCallback onCancel;

  /// Helper untuk menampilkan dialog dan mengembalikan jumlah yang di-check-in,
  /// atau `null` jika petugas membatalkan.
  static Future<int?> show(
    BuildContext context, {
    required ScanResult scanResult,
    bool isOffline = false,
  }) {
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GroupHeadcountDialog(
        scanResult: scanResult,
        isOffline: isOffline,
        onConfirm: (count) => Navigator.of(dialogContext).pop(count),
        onCancel: () => Navigator.of(dialogContext).pop(null),
      ),
    );
  }

  @override
  State<GroupHeadcountDialog> createState() => _GroupHeadcountDialogState();
}

class _GroupHeadcountDialogState extends State<GroupHeadcountDialog> {
  late int _headcount;
  late final int _quota;

  bool get _isQuotaKnown => _quota > 0;

  @override
  void initState() {
    super.initState();
    _quota = widget.scanResult.visitorCount;
    _headcount = _quota > 0 ? _quota : 1;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final guestName = widget.scanResult.visitorName ?? 'Pengunjung';
    final isExact = _isQuotaKnown && _headcount == _quota;
    final isExceeded = _isQuotaKnown && _headcount > _quota;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: c.outline, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.isOffline)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: c.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: c.secondary.withValues(alpha: 0.3)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(AppIcons.wifiOff, size: 15, color: c.secondary),
                          const SizedBox(width: 6),
                          Text(
                            context.trSafe(
                              'groupTicket.offlineBadge',
                              'Mode Offline · Antrean Perangkat',
                            ),
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Header Icon & Title
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Center(
                        child: Icon(AppIcons.people, color: c.primary, size: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.trSafe(
                              'groupTicket.dialogTitle',
                              'Konfirmasi Jumlah Hadir',
                            ),
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: c.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$guestName · ${widget.scanResult.ticketCode}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: c.inkMuted,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Kartu Informasi Kuota Tiket
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: c.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.outline),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _isQuotaKnown
                              ? context.trSafe(
                                  'groupTicket.bookedQuota',
                                  'Kuota Tiket: $_quota Orang',
                                  namedArgs: {'count': '$_quota'},
                                )
                              : context.trSafe(
                                  'groupTicket.quotaFromPhysical',
                                  'Kuota Tiket (Lihat Fisik)',
                                ),
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 13,
                            color: c.inkMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isQuotaKnown ? '$_quota Orang' : 'Sesuai Fisik',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: _isQuotaKnown ? 16 : 13.5,
                          fontWeight: FontWeight.w700,
                          color: c.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Label & Stepper Jumlah Orang Hadir
                Text(
                  context.trSafe(
                    'groupTicket.actualCount',
                    'Jumlah Hadir Saat Ini',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.inkMuted,
                  ),
                ),
                const SizedBox(height: 12),

                // Stepper Row: [-] [ Display Count ] [+]
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Button Minus
                    _stepperButton(
                      icon: Icons.remove,
                      onTap: _headcount > 1
                          ? () => setState(() => _headcount--)
                          : null,
                      context: context,
                    ),
                    const SizedBox(width: 18),

                    // Display Angka Hadir
                    Container(
                      width: 80,
                      height: 52,
                      decoration: BoxDecoration(
                        color: c.surfaceAlt,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isExceeded ? c.cancelled : c.outline,
                          width: isExceeded ? 1.5 : 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$_headcount',
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: isExceeded ? c.cancelled : c.ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),

                    // Button Plus
                    _stepperButton(
                      icon: Icons.add,
                      onTap: () => setState(() => _headcount++),
                      context: context,
                    ),
                  ],
                ),

                // Quick Button (jika kuota diketahui)
                if (_isQuotaKnown) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: c.primary,
                      ),
                      onPressed: _headcount == _quota
                          ? null
                          : () => setState(() => _headcount = _quota),
                      icon: const Icon(AppIcons.checkCircle, size: 16),
                      label: Text(
                        context.trSafe(
                          'groupTicket.matchExact',
                          'Sesuai ($_quota Orang)',
                          namedArgs: {'count': '$_quota'},
                        ),
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],

                // Kotak Status/Peringatan:
                // - Jika kuota melebihi: tampilkan warning kenapa tombol dinonaktifkan
                // - Jika online & kuota diketahui: tampilkan ringkasan status hadir
                // - Jika offline: tidak ada kotak warning (tampilan bersih/clean)
                if (isExceeded || (!widget.isOffline && _isQuotaKnown)) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isExceeded
                          ? c.cancelled.withValues(alpha: 0.1)
                          : (isExact
                              ? c.valid.withValues(alpha: 0.1)
                              : c.inkMuted.withValues(alpha: 0.08)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isExceeded
                            ? c.cancelled.withValues(alpha: 0.35)
                            : (isExact
                                ? c.valid.withValues(alpha: 0.35)
                                : c.outline),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isExceeded
                              ? AppIcons.warning
                              : (isExact ? AppIcons.checkCircle : AppIcons.info),
                          size: 18,
                          color: isExceeded
                              ? c.cancelled
                              : (isExact ? c.valid : c.inkMuted),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isExceeded
                                ? context.trSafe(
                                    'groupTicket.statusExceeded',
                                    'Jumlah hadir ($_headcount orang) melebihi kuota ($_quota orang). Tiket ditolak dan tidak dapat dikonfirmasi. Kelebihan ${_headcount - _quota} orang harus membeli tiket baru terpisah.',
                                    namedArgs: {
                                      'actual': '$_headcount',
                                      'quota': '$_quota',
                                      'extra': '${_headcount - _quota}',
                                    },
                                  )
                                : (isExact
                                    ? context.trSafe(
                                        'groupTicket.statusExact',
                                        'Jumlah hadir sesuai dengan kuota tiket ($_quota orang).',
                                        namedArgs: {'count': '$_quota'},
                                      )
                                    : context.trSafe(
                                        'groupTicket.statusLess',
                                        '$_headcount orang dicatat masuk (${_quota - _headcount} orang tidak hadir).',
                                        namedArgs: {
                                          'actual': '$_headcount',
                                          'extra': '${_quota - _headcount}',
                                        },
                                      )),
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 12.5,
                              height: 1.4,
                              color: isExceeded
                                  ? c.cancelled
                                  : (isExact ? c.valid : c.inkMuted),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Tombol Konfirmasi Check-In Utama (Ditolak & Nonaktif bila melebihi kuota)
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isExceeded
                          ? c.cancelled.withValues(alpha: 0.12)
                          : c.valid,
                      foregroundColor: isExceeded ? c.cancelled : Colors.white,
                      disabledBackgroundColor:
                          c.cancelled.withValues(alpha: 0.12),
                      disabledForegroundColor: c.cancelled,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: isExceeded
                            ? BorderSide(
                                color: c.cancelled.withValues(alpha: 0.35),
                                width: 1.2,
                              )
                            : BorderSide.none,
                      ),
                      elevation: 0,
                    ),
                    onPressed: isExceeded
                        ? null
                        : () => widget.onConfirm(_headcount),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isExceeded) ...[
                            Icon(AppIcons.block, size: 18, color: c.cancelled),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            isExceeded
                                ? context.trSafe(
                                    'groupTicket.rejectedExceeded',
                                    'Tiket Ditolak (Melebihi Kuota)',
                                  )
                                : (widget.isOffline
                                    ? context.trSafe(
                                        'groupTicket.confirmOffline',
                                        'Konfirmasi Hadir ($_headcount Orang) · Offline',
                                        namedArgs: {'count': '$_headcount'},
                                      )
                                    : context.trSafe(
                                        'groupTicket.confirmCheckIn',
                                        'Konfirmasi Masuk ($_headcount Orang)',
                                        namedArgs: {'count': '$_headcount'},
                                      )),
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: isExceeded ? c.cancelled : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Tombol Batal
                SizedBox(
                  height: 42,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: c.inkMuted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: widget.onCancel,
                    child: Text(
                      context.trSafe('groupTicket.cancel', 'Batal'),
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required VoidCallback? onTap,
    required BuildContext context,
  }) {
    final c = context.colors;
    final enabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: enabled ? c.surfaceAlt : c.surfaceAlt.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? c.outline : c.outline.withValues(alpha: 0.5),
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: enabled ? c.ink : c.inkMuted.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}
