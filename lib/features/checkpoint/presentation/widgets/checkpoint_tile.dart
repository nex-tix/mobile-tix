import 'package:flutter/material.dart';
import 'package:mobile_tix/core/constants/app_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/checkpoint.dart';

/// Checkpoint option card based on `newDesign/2._checkpoint_selection/code.html`.
///
/// Features:
/// - Surface card (`context.colors.surface`)
/// - Leading lock icon & gate title
/// - Glowing Gold outline and custom radio button when selected
class CheckpointTile extends StatelessWidget {
  const CheckpointTile({
    super.key,
    required this.checkpoint,
    required this.selected,
    required this.onTap,
  });

  final Checkpoint checkpoint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? context.colors.secondary
                    : context.colors.outline,
                width: selected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                // Leading Lock Icon
                Icon(AppIcons.lock, size: 18, color: context.colors.inkMuted),
                const SizedBox(width: 14),

                // Gate Title & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            checkpoint.gate,
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: context.colors.ink,
                              letterSpacing: 0.2,
                            ),
                          ),
                          if (!checkpoint.open) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.colors.primaryTint,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'DITUTUP',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (checkpoint.name.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          checkpoint.name,
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 12.5,
                            color: context.colors.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Radio Indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? context.colors.secondary
                          : context.colors.outline,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: selected ? 10 : 0,
                      height: selected ? 10 : 0,
                      decoration: BoxDecoration(
                        color: context.colors.secondary,
                        shape: BoxShape.circle,
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
}
