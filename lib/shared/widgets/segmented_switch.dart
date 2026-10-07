import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A two-to-three option switch with a sliding indicator.
///
/// This is the platform's segmented control, themed: the chosen cell takes the raised
/// paper tone and the ink weight, the rest stay on the sunken track, and the indicator
/// is the only thing that moves. Used wherever the app has mutually exclusive jobs —
/// scan mode, reporting period.
class SegmentedSwitch extends StatelessWidget {
  const SegmentedSwitch({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.height = AppSpacing.touchTarget,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText.of(context);
    final count = labels.length;
    final fraction = 1 / count;

    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: c.outline),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: Alignment(
              count > 1 ? -1 + (2 * index) / (count - 1) : -1,
              0,
            ),
            duration: AppSpacing.base,
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: fraction,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  border: Border.all(color: c.outlineStrong),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < count; i++)
                Expanded(
                  child: Semantics(
                    selected: i == index,
                    button: true,
                    child: InkWell(
                      onTap: () => onChanged(i),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: AppSpacing.fast,
                          style: text.label.copyWith(
                            fontSize: 12,
                            letterSpacing: 1.0,
                            color: i == index ? c.ink : c.inkMuted,
                            fontWeight: i == index
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                          child: Text(labels[i], maxLines: 1),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
