import 'package:flutter/material.dart';

import '../../../../core/constants/ticket_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/i18n_helper.dart';
import '../../../../shared/widgets/stamp_mark.dart';
import '../../data/models/scan_outcome.dart';

/// Full modal feedback sheet based on Screen 8 (Valid) & Screen 9 (Already Used).
///
/// Satu sinyal verdict saja: [StampMark] mendarat di tengah sheet. Warna status
/// tidak diulang di circle, judul, dan tombol — tombol bawah sengaja netral
/// supaya stamp tetap satu-satunya kejadian jenuh di layar ini.
class ScanResultSheet extends StatefulWidget {
  const ScanResultSheet({
    super.key,
    required this.outcome,
    this.autoDismiss = false,
    this.onRetry,
  });

  final ScanOutcome outcome;
  final bool autoDismiss;
  final VoidCallback? onRetry;

  static Future<void> show(
    BuildContext context, {
    required ScanOutcome outcome,
    bool autoDismiss = false,
    VoidCallback? onRetry,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (_) => ScanResultSheet(
        outcome: outcome,
        autoDismiss: autoDismiss,
        onRetry: onRetry,
      ),
    );
  }

  @override
  State<ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends State<ScanResultSheet>
    with SingleTickerProviderStateMixin {
  AnimationController? _dwell;

  @override
  void initState() {
    super.initState();
    final isGroup = widget.outcome.tickets > 1 || widget.outcome.actualAdmitted != null;
    if (widget.autoDismiss && widget.outcome.status == TicketStatus.valid && !isGroup) {
      _dwell =
          AnimationController(
              vsync: this,
              duration: const Duration(milliseconds: 3800),
            )
            ..forward().whenComplete(() {
              if (mounted) Navigator.of(context).maybePop();
            });
    }
  }

  @override
  void dispose() {
    _dwell?.dispose();
    super.dispose();
  }

  String _instructionForStatus(BuildContext context, TicketStatus status) =>
      switch (status) {
        TicketStatus.valid => context.trSafe(
          'ticket.instructionValid',
          status.instruction,
        ),
        TicketStatus.alreadyUsed => context.trSafe(
          'ticket.instructionAlreadyUsed',
          status.instruction,
        ),
        TicketStatus.expired => context.trSafe(
          'ticket.instructionExpired',
          status.instruction,
        ),
        TicketStatus.notYetValid => context.trSafe(
          'ticket.instructionNotYetValid',
          status.instruction,
        ),
        TicketStatus.notFound => context.trSafe(
          'ticket.instructionNotFound',
          status.instruction,
        ),
        TicketStatus.cancelled => context.trSafe(
          'ticket.instructionCancelled',
          status.instruction,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final outcome = widget.outcome;
    final status = outcome.status;
    final isValid = status == TicketStatus.valid;
    final isUsed = status == TicketStatus.alreadyUsed;

    final String statusTitle;
    if (isValid) {
      statusTitle = context.trSafe('ticket.valid', 'VALID');
    } else if (isUsed) {
      statusTitle = context.trSafe('ticket.alreadyUsed', 'ALREADY USED');
    } else if (status == TicketStatus.expired) {
      statusTitle = context.trSafe('ticket.expired', 'EXPIRED');
    } else if (status == TicketStatus.notYetValid) {
      statusTitle = context.trSafe('ticket.notYetValid', 'BELUM BERLAKU');
    } else if (status == TicketStatus.notFound) {
      statusTitle = context.trSafe('ticket.invalid', 'INVALID TICKET');
    } else {
      statusTitle = context.trSafe('ticket.cancelled', 'CANCELLED');
    }

    final screenHeight = MediaQuery.sizeOf(context).height;

    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusSheet),
        ),
        border: Border(top: BorderSide(color: context.colors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: context.colors.outlineStrong.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),

            // Auto-dismiss countdown bar for valid scans
            if (_dwell != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 4,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: AnimatedBuilder(
                    animation: _dwell!,
                    builder: (context, _) => LinearProgressIndicator(
                      value: (1 - _dwell!.value).clamp(0.0, 1.0),
                      minHeight: 2.5,
                      backgroundColor: context.colors.outlineStrong.withValues(
                        alpha: 0.08,
                      ),
                      valueColor: AlwaysStoppedAnimation(context.colors.valid),
                    ),
                  ),
                ),
              ),

            // Center: satu sinyal verdict — stamp.
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StampMark(
                    status: status,
                    word: statusTitle,
                    subline:
                        '${outcome.gate ?? 'Gate 1'} · ${Fmt.clockWita(outcome.at)}',
                  ),
                  const SizedBox(height: 22),
                  Builder(
                    builder: (context) {
                      final String visitorSubtitle;
                      if (outcome.actualAdmitted != null &&
                          outcome.actualAdmitted != outcome.tickets) {
                        visitorSubtitle = context.trSafe(
                          'groupTicket.admittedInfo',
                          '${outcome.actualAdmitted} dari ${outcome.tickets} Pengunjung Hadir',
                          namedArgs: {
                            'actual': '${outcome.actualAdmitted}',
                            'quota': '${outcome.tickets}',
                          },
                        );
                      } else {
                        visitorSubtitle = context.trSafe(
                          'ticket.visitor',
                          '${outcome.tickets} Visitor',
                          namedArgs: {'count': '${outcome.tickets}'},
                        );
                      }

                      return Text(
                        '${outcome.category ?? context.trSafe('ticket.defaultCategory', 'Tiket')} · $visitorSubtitle',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 15.5,
                          color: context.colors.ink,
                        ),
                      );
                    },
                  ),

                  // Kode yang benar-benar dibaca: hanya ditampilkan saat TIDAK
                  // DITEMUKAN, supaya operator bisa membedakan kode salah baca
                  // dari kode yang memang tidak ada di sistem.
                  if (status == TicketStatus.notFound &&
                      outcome.code.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      outcome.code,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12.5,
                        letterSpacing: 0.6,
                        color: context.colors.inkFaint,
                      ),
                    ),
                  ],

                  // Rejection note / reason if not valid
                  if (!isValid) ...[
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        String note;
                        if (isUsed && outcome.previousUseAt != null) {
                          note = context.trSafe(
                            'ticket.previousUse',
                            'Dipakai sebelumnya: ${Fmt.clockSeconds(outcome.previousUseAt!)} (${outcome.previousUseGate ?? "(gate tidak tercatat)"})',
                            namedArgs: {
                              'time': Fmt.clockSeconds(outcome.previousUseAt!),
                              'gate':
                                  outcome.previousUseGate ??
                                  "(gate tidak tercatat)",
                            },
                          );
                        } else if (outcome.message != null &&
                            outcome.message!.isNotEmpty) {
                          note = outcome.message!;
                        } else {
                          note = _instructionForStatus(context, outcome.status);
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            note,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.colors.inkMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            // Bottom action: netral, lebih tenang daripada verdict.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: context.colors.surface,
                    side: BorderSide(color: context.colors.outlineStrong),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).maybePop();
                  },
                  child: Text(
                    context.trSafe('scanner.scanNext', 'Scan Next'),
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: context.colors.ink,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
