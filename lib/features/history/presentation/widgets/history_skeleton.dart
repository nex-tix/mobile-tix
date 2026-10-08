// File: history_skeleton.dart
// Skeleton shimmer loader untuk HistoryScreen.

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/shimmer_loading.dart';

/// Skeleton loader yang mencerminkan daftar riwayat scan pada HistoryScreen.
class HistorySkeleton extends StatelessWidget {
  const HistorySkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => _historyRowSkeleton(context),
      ),
    );
  }

  Widget _historyRowSkeleton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        children: [
          // Status Icon Circle
          ShimmerBox(
            width: 36,
            height: 36,
            borderRadius: 18,
            color: context.colors.surfaceAlt,
          ),
          const SizedBox(width: 14),

          // Code + Buyer/Gate
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: 140,
                  height: 16,
                  borderRadius: 4,
                  color: context.colors.surfaceAlt,
                ),
                const SizedBox(height: 6),
                ShimmerBox(
                  width: 90,
                  height: 12,
                  borderRadius: 4,
                  color: context.colors.surfaceAlt,
                ),
              ],
            ),
          ),

          // Timestamp
          ShimmerBox(
            width: 48,
            height: 12,
            borderRadius: 4,
            color: context.colors.surfaceAlt,
          ),
        ],
      ),
    );
  }
}
