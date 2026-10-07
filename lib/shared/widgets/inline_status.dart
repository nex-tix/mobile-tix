import 'package:flutter/material.dart';
import 'package:mobile_tix/core/constants/app_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

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
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.28),
                  blurRadius: 0,
                  spreadRadius: 2.5,
                ),
              ],
            ),
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
