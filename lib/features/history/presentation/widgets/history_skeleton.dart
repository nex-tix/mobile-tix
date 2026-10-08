// File: history_skeleton.dart
// Skeleton shimmer loader untuk HistoryScreen.

import 'package:flutter/material.dart';

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
        itemBuilder: (_, _) => _historyRowSkeleton(),
      ),
    );
  }

  Widget _historyRowSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF212B2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334147)),
      ),
      child: Row(
        children: [
          // Status Icon Circle
          const ShimmerBox(width: 36, height: 36, borderRadius: 18),
          const SizedBox(width: 14),

          // Code + Buyer/Gate
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 140, height: 16, borderRadius: 4),
                SizedBox(height: 6),
                ShimmerBox(width: 90, height: 12, borderRadius: 4),
              ],
            ),
          ),

          // Timestamp
          const ShimmerBox(width: 48, height: 12, borderRadius: 4),
        ],
      ),
    );
  }
}
