// File: dashboard_skeleton.dart
// Skeleton shimmer loader untuk DashboardScreen.

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
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
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.colors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: 40,
                  height: 40,
                  borderRadius: 12,
                  color: context.colors.surfaceAlt,
                ),
                const SizedBox(height: 16),
                ShimmerBox(
                  width: 120,
                  height: 44,
                  borderRadius: 8,
                  color: context.colors.surfaceAlt,
                ),
                const SizedBox(height: 8),
                ShimmerBox(
                  width: 60,
                  height: 14,
                  borderRadius: 4,
                  color: context.colors.surfaceAlt,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Valid Card Skeleton
          _metricSkeleton(context),
        ],
      ),
    );
  }

  Widget _metricSkeleton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(
            width: 18,
            height: 18,
            borderRadius: 4,
            color: context.colors.surfaceAlt,
          ),
          const SizedBox(height: 12),
          ShimmerBox(
            width: 70,
            height: 30,
            borderRadius: 6,
            color: context.colors.surfaceAlt,
          ),
          const SizedBox(height: 8),
          ShimmerBox(
            width: 45,
            height: 12,
            borderRadius: 4,
            color: context.colors.surfaceAlt,
          ),
        ],
      ),
    );
  }
}
