import 'package:flutter/material.dart';

import '../../../../core/constants/ticket_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Review furniture, clearly labelled as such.
///
/// The brief asks that all five verdicts and the camera-permission wall be visible in
/// the design. A real gate app has no such row, so it stays visually quiet — outlined,
/// small caps, no fills — and sits at the very bottom under its own label.
class DemoControls extends StatelessWidget {
  const DemoControls({
    super.key,
    required this.onPick,
    required this.cameraBlocked,
    required this.onToggleCamera,
  });

  final ValueChanged<TicketStatus> onPick;
  final bool cameraBlocked;
  final VoidCallback onToggleCamera;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.science_outlined, size: 15, color: c.inkFaint),
            const SizedBox(width: 6),
            Text('UJI TAMPILAN', style: text.label),
          ],
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final status in TicketStatus.values)
              _DemoChip(
                label: status.shortLabel.toUpperCase(),
                icon: status.icon,
                color: status.ink(c),
                onTap: () => onPick(status),
              ),
            _DemoChip(
              label: 'IZIN KAMERA',
              icon: cameraBlocked
                  ? Icons.no_photography_outlined
                  : Icons.photo_camera_outlined,
              color: cameraBlocked ? c.used : c.inkMuted,
              active: cameraBlocked,
              onTap: onToggleCamera,
            ),
          ],
        ),
      ],
    );
  }
}

class _DemoChip extends StatelessWidget {
  const _DemoChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: active ? c.primaryTint : c.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          border: Border.all(color: active ? c.primary : c.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: text.label.copyWith(
                color: color,
                fontSize: 10.5,
                letterSpacing: 0.9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
