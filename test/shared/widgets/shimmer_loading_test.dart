// File: shimmer_loading_test.dart
// Widget test ShimmerLoading, DashboardSkeleton, & HistorySkeleton (Commit 8.2)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/features/dashboard/presentation/widgets/dashboard_skeleton.dart';
import 'package:mobile_tix/features/history/presentation/widgets/history_skeleton.dart';
import 'package:mobile_tix/shared/widgets/shimmer_loading.dart';

void main() {
  group('Shimmer & Skeleton Tests', () {
    testWidgets('ShimmerLoading renders child correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerLoading(
              child: Text('Shimmering content'),
            ),
          ),
        ),
      );

      expect(find.text('Shimmering content'), findsOneWidget);
    });

    testWidgets('DashboardSkeleton renders without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardSkeleton(),
          ),
        ),
      );

      expect(find.byType(DashboardSkeleton), findsOneWidget);
      expect(find.byType(ShimmerLoading), findsOneWidget);
      expect(find.byType(ShimmerBox), findsWidgets);
    });

    testWidgets('HistorySkeleton renders list of skeleton rows', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HistorySkeleton(itemCount: 4),
          ),
        ),
      );

      expect(find.byType(HistorySkeleton), findsOneWidget);
      expect(find.byType(ShimmerLoading), findsOneWidget);
      expect(find.byType(ShimmerBox), findsWidgets);
    });
  });
}
