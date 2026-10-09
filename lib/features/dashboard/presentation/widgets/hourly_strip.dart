import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/gate_stats.dart';

/// Entries per operating hour.
///
/// A real series, drawn plain: one column per hour, sitting on a baseline, with the
/// peak hour inked in the primary so the second-lane decision can be made from the
/// shape alone. No smoothing, no area fill, no fake curve.
class HourlyStrip extends StatelessWidget {
  const HourlyStrip({super.key, required this.stats, this.height = 78});

  final GateStats stats;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText.of(context);
    final values = stats.hourly;
    final peak = stats.peakCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < values.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: values[i] / peak),
                          duration: Duration(milliseconds: 420 + i * 28),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => Container(
                            height: (height - 4) * value + 3,
                            decoration: BoxDecoration(
                              color: i == stats.peakIndex
                                  ? c.secondary
                                  : c.surfaceAlt,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 1),
        Container(height: 1, color: c.outline),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            for (var i = 0; i < values.length; i++)
              Expanded(
                child: Text(
                  i % 3 == 0
                      ? (stats.hourStart + i).toString().padLeft(2, '0')
                      : '',
                  textAlign: TextAlign.center,
                  style: text.label.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.2,
                    color: c.inkMuted,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
