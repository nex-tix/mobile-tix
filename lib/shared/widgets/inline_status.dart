import 'package:flutter/material.dart';
import 'package:mobile_tix/core/constants/app_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/i18n_helper.dart';

/// The connection state as one quiet pill — shared by the scanner header,
/// dashboard and profile so the app carries exactly one connection affordance.
/// The dot carries the status colour; the word stays ink, so the pill adds one
/// accent instead of four.
class ConnectionPill extends StatelessWidget {
  const ConnectionPill({
    super.key,
    required this.online,
    this.onRefresh,
    this.onToggle,
    this.isChecking = false,
  });

  final bool online;
  final VoidCallback? onRefresh;
  final VoidCallback? onToggle;
  final bool isChecking;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText.of(context);
    final refreshAction = onRefresh ?? onToggle;

    final pill = Container(
      padding: EdgeInsets.symmetric(
        horizontal: online ? AppSpacing.xs + 4 : AppSpacing.xs + 6,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: online ? c.surface : c.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: online ? c.outline : c.primary.withValues(alpha: 0.35),
          width: 1.1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: online ? c.valid : c.primary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            context.trSafe(
              online ? 'common.online' : 'common.offline',
              online ? 'Online' : 'Offline',
            ),
            style: text.label.copyWith(
              color: online ? c.ink : c.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              fontSize: 11.5,
            ),
          ),
          if (!online) ...[
            const SizedBox(width: 6),
            if (isChecking)
              SizedBox(
                width: 11,
                height: 11,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: c.primary,
                ),
              )
            else
              Icon(
                AppIcons.refresh,
                size: 13,
                color: c.primary,
              ),
          ],
        ],
      ),
    );

    // Saat online: tidak dapat ditekan / di-toggle manual
    // Saat offline: dapat ditekan untuk mencari sinyal / refresh
    if (online || refreshAction == null) return pill;

    return Tooltip(
      message: 'Ketuk untuk mencari sinyal lagi',
      child: InkWell(
        onTap: isChecking ? null : refreshAction,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs / 2),
          child: pill,
        ),
      ),
    );
  }
}

/// The connection / shift indicator: a dot and a word.
class InlineStatus extends StatelessWidget {
  const InlineStatus({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.tint,
    this.onTap,
    this.compact = false,
  });

  final String label;
  final Color color;

  /// When set, the word is preceded by an icon instead of a dot.
  final IconData? icon;

  /// Background for the tappable, chip-shaped form.
  final Color? tint;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final word = Text(
      label.toUpperCase(),
      style: text.label.copyWith(color: color, letterSpacing: 0.7),
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, size: 13, color: color)
        else
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        const SizedBox(width: AppSpacing.xs),
        word,
      ],
    );

    if (onTap == null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 2 : 6),
        child: content,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        ),
        child: content,
      ),
    );
  }
}

/// The active checkpoint, always visible in the shell. Tappable: at a gate a staff
/// member moved to another lane mid-shift needs to re-point it in one tap.
class CheckpointChip extends StatelessWidget {
  const CheckpointChip({
    super.key,
    required this.name,
    this.gateLabel,
    this.onTap,
  });

  final String name;
  final String? gateLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText.of(context);

    final chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: c.primaryTint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        border: Border.all(color: c.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.sensorDoor, size: 15, color: c.onPrimaryTint),
          const SizedBox(width: 6),
          Text(
            name,
            style: text.chip.copyWith(color: c.onPrimaryTint),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(AppIcons.unfoldMore, size: 15, color: c.onPrimaryTint),
          ],
        ],
      ),
    );

    if (onTap == null) return chip;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget),
        alignment: Alignment.center,
        child: chip,
      ),
    );
  }
}
