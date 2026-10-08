import 'package:flutter/material.dart';
import 'package:mobile_tix/core/constants/app_icons.dart';

import '../../../../core/constants/ticket_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/i18n_helper.dart';
import '../../data/models/scan_outcome.dart';

/// Full modal feedback sheet based on Screen 8 (Valid) & Screen 9 (Already Used).
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
    if (widget.autoDismiss && widget.outcome.status == TicketStatus.valid) {
      _dwell = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3800),
      )..forward().whenComplete(() {
          if (mounted) Navigator.of(context).maybePop();
        });
    }
  }

  @override
  void dispose() {
    _dwell?.dispose();
    super.dispose();
  }

  String _instructionForStatus(BuildContext context, TicketStatus status) => switch (status) {
    TicketStatus.valid => context.trSafe('ticket.instructionValid', status.instruction),
    TicketStatus.alreadyUsed => context.trSafe('ticket.instructionAlreadyUsed', status.instruction),
    TicketStatus.expired => context.trSafe('ticket.instructionExpired', status.instruction),
    TicketStatus.notFound => context.trSafe('ticket.instructionNotFound', status.instruction),
    TicketStatus.cancelled => context.trSafe('ticket.instructionCancelled', status.instruction),
  };

  @override
  Widget build(BuildContext context) {
    final outcome = widget.outcome;
    final status = outcome.status;
    final isValid = status == TicketStatus.valid;
    final isUsed = status == TicketStatus.alreadyUsed;
    final isExpired = status == TicketStatus.expired;

    // Semantic visual configuration
    final Color badgeColor;
    final Color textColor;
    final Color btnBgColor;
    final Color btnTextColor;
    final String statusTitle;
    final IconData statusIcon;

    if (isValid) {
      badgeColor = const Color(0xFF2ECC71);
      textColor = const Color(0xFF2ECC71);
      btnBgColor = const Color(0xFF2ECC71);
      btnTextColor = Colors.white;
      statusTitle = context.trSafe('ticket.valid', 'VALID');
      statusIcon = AppIcons.check;
    } else if (isUsed) {
      badgeColor = const Color(0xFFCF4647);
      textColor = const Color(0xFFCF4647);
      btnBgColor = const Color(0xFFCF4647);
      btnTextColor = const Color(0xFFF8F6F6);
      statusTitle = context.trSafe('ticket.alreadyUsed', 'ALREADY USED');
      statusIcon = AppIcons.close;
    } else if (isExpired) {
      badgeColor = const Color(0xFFF5D061);
      textColor = const Color(0xFFF5D061);
      btnBgColor = const Color(0xFFF5D061);
      btnTextColor = const Color(0xFF1E272B);
      statusTitle = context.trSafe('ticket.expired', 'EXPIRED');
      statusIcon = AppIcons.schedule;
    } else {
      badgeColor = const Color(0xFFCF4647);
      textColor = const Color(0xFFCF4647);
      btnBgColor = const Color(0xFFCF4647);
      btnTextColor = const Color(0xFFF8F6F6);
      statusTitle = status == TicketStatus.notFound
          ? context.trSafe('ticket.invalid', 'INVALID TICKET')
          : context.trSafe('ticket.cancelled', 'CANCELLED');
      statusIcon = AppIcons.errorOutline;
    }

    final screenHeight = MediaQuery.sizeOf(context).height;

    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        border: Border(
          top: BorderSide(
            color: context.colors.outline,
            width: 1,
          ),
        ),
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
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),

            // Auto-dismiss countdown bar for valid scans
            if (_dwell != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: AnimatedBuilder(
                    animation: _dwell!,
                    builder: (context, _) => LinearProgressIndicator(
                      value: (1 - _dwell!.value).clamp(0.0, 1.0),
                      minHeight: 2.5,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF2ECC71)),
                    ),
                  ),
                ),
              ),

            // Center Feedback Block
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Clean Solid Badge (no blur glow)
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: badgeColor,
                    ),
                    child: Center(
                      child: Icon(
                        statusIcon,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                      // Status Title
                      Text(
                        statusTitle,
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Meta Details Block
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            // Ticket Type / Pax count
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  AppIcons.people,
                                  size: 19,
                                  color: context.colors.inkMuted,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${outcome.category ?? context.trSafe('ticket.defaultCategory', 'Tiket')} · ${context.trSafe('ticket.visitor', '${outcome.tickets} Visitor', namedArgs: {'count': '${outcome.tickets}'})}',
                                  style: TextStyle(
                                    fontFamily: 'DMSans',
                                    fontSize: 15.5,
                                    color: context.colors.ink,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Timestamp
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  AppIcons.accessTime,
                                  size: 19,
                                  color: context.colors.inkMuted,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  Fmt.clockSeconds(outcome.at),
                                  style: TextStyle(
                                    fontFamily: 'DMSans',
                                    fontSize: 15.5,
                                    color: context.colors.ink,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Gate Location
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  AppIcons.location,
                                  size: 19,
                                  color: context.colors.inkMuted,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  outcome.gate ?? 'Gate 1',
                                  style: TextStyle(
                                    fontFamily: 'DMSans',
                                    fontSize: 15.5,
                                    color: context.colors.ink,
                                  ),
                                ),
                              ],
                            ),

                            // Rejection note / reason if not valid
                            if (!isValid) ...[
                              const SizedBox(height: 12),
                              Text(
                                isUsed && outcome.previousUseAt != null
                                    ? context.trSafe('ticket.previousUse', 'Dipakai sebelumnya: ${Fmt.clockSeconds(outcome.previousUseAt!)} (${outcome.previousUseGate ?? "Gate 1"})', namedArgs: {
                                        'time': Fmt.clockSeconds(outcome.previousUseAt!),
                                        'gate': outcome.previousUseGate ?? "Gate 1",
                                      })
                                    : _instructionForStatus(context, outcome.status),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFFFB3AF),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Action: Scan Next Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: btnBgColor,
                            foregroundColor: btnTextColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).maybePop();
                          },
                          child: Text(
                            context.trSafe('scanner.scanNext', 'Scan Next'),
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: btnTextColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
