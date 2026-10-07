import 'package:flutter/material.dart';

import '../../core/constants/ticket_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum StatusBadgeVariant {
  /// Tinted block — the sheet, the dashboard, anywhere there is room.
  pill,

  /// Coloured word only — dense log rows where a pill per line would become noise.
  inline,
}

/// One verdict, two volumes. The colour role comes from [TicketStatus], so the word
/// and its colour can never drift apart between screens.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.variant = StatusBadgeVariant.pill,
    this.withIcon = false,
    this.label,
  });

  final TicketStatus status;
  final StatusBadgeVariant variant;
  final bool withIcon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText.of(context);
    final ink = status.ink(c);
    final word = (label ?? status.shortLabel).toUpperCase();

    if (variant == StatusBadgeVariant.inline) {
      return Text(
        word,
        style: text.label.copyWith(
          color: ink,
          letterSpacing: 0.7,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: status.tint(c),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        border: Border.all(color: ink.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (withIcon) ...[
            Icon(status.icon, size: 13, color: ink),
            const SizedBox(width: 5),
          ],
          Text(
            word,
            style: text.label.copyWith(
              color: ink,
              letterSpacing: 0.7,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
