// File: dashboard_skeleton.dart
// Skeleton shimmer loader untuk DashboardScreen.

import 'package:flutter/material.dart';

import '../../../../shared/widgets/shimmer_loading.dart';

/// Skeleton loader yang mencerminkan tata letak kartu metrik pada DashboardScreen.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Visitors Card Skeleton
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF212B2F),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF3E4E55)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 40, height: 40, borderRadius: 12),
                const SizedBox(height: 16),
                const ShimmerBox(width: 120, height: 44, borderRadius: 8),
                const SizedBox(height: 8),
                const ShimmerBox(width: 60, height: 14, borderRadius: 4),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Valid & Rejected Cards Skeleton
          Row(
            children: [
              Expanded(child: _metricSkeleton()),
              const SizedBox(width: 12),
              Expanded(child: _metricSkeleton()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricSkeleton() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF212B2F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF3E4E55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerBox(width: 28, height: 28, borderRadius: 14),
          SizedBox(height: 14),
          ShimmerBox(width: 70, height: 32, borderRadius: 6),
          SizedBox(height: 8),
          ShimmerBox(width: 45, height: 12, borderRadius: 4),
        ],
      ),
    );
  }
}
