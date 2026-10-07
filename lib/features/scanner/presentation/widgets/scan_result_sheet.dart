import 'package:flutter/material.dart';

import '../../../../core/constants/ticket_status.dart';
import '../../../../core/utils/formatters.dart';
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
      btnTextColor = const Color(0xFF2A363B);
      statusTitle = 'VALID';
      statusIcon = Icons.check_rounded;
    } else if (isUsed) {
      badgeColor = const Color(0xFFCF4647);
      textColor = const Color(0xFFCF4647);
      btnBgColor = const Color(0xFFCF4647);
      btnTextColor = const Color(0xFFF8F6F6);
      statusTitle = 'ALREADY USED';
      statusIcon = Icons.close_rounded;
    } else if (isExpired) {
      badgeColor = const Color(0xFFF5D061);
      textColor = const Color(0xFFF5D061);
      btnBgColor = const Color(0xFFF5D061);
      btnTextColor = const Color(0xFF2A363B);
      statusTitle = 'EXPIRED';
      statusIcon = Icons.schedule_rounded;
    } else {
      badgeColor = const Color(0xFFCF4647);
      textColor = const Color(0xFFCF4647);
      btnBgColor = const Color(0xFFCF4647);
      btnTextColor = const Color(0xFFF8F6F6);
      statusTitle = status == TicketStatus.notFound ? 'INVALID TICKET' : 'CANCELLED';
      statusIcon = Icons.error_outline_rounded;
    }

    final screenHeight = MediaQuery.sizeOf(context).height;

    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF212B2F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        border: Border(
          top: BorderSide(
            color: Color(0xFF3E4E55),
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
                          fontFamily: 'Barlow',
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
                                const Icon(
                                  Icons.people_outline_rounded,
                                  size: 19,
                                  color: Color(0xFFA3B1B7),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${outcome.category ?? "Adult"} · ${outcome.tickets} Visitor',
                                  style: const TextStyle(
                                    fontFamily: 'Barlow',
                                    fontSize: 15.5,
                                    color: Color(0xFFF8F6F6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Timestamp
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 19,
                                  color: Color(0xFFA3B1B7),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  Fmt.clockSeconds(outcome.at),
                                  style: const TextStyle(
                                    fontFamily: 'Barlow',
                                    fontSize: 15.5,
                                    color: Color(0xFFF8F6F6),
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
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 19,
                                  color: Color(0xFFA3B1B7),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  outcome.gate ?? 'Gate 1',
                                  style: const TextStyle(
                                    fontFamily: 'Barlow',
                                    fontSize: 15.5,
                                    color: Color(0xFFF8F6F6),
                                  ),
                                ),
                              ],
                            ),

                            // Rejection note / reason if not valid
                            if (!isValid) ...[
                              const SizedBox(height: 12),
                              Text(
                                isUsed && outcome.previousUseAt != null
                                    ? 'Dipakai sebelumnya: ${Fmt.clockSeconds(outcome.previousUseAt!)} (${outcome.previousUseGate ?? "Gate 1"})'
                                    : outcome.status.instruction,
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
                            'Scan Next',
                            style: TextStyle(
                              fontFamily: 'Barlow',
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
