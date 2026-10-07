import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Simulated loading, in the shape of the content that is coming.
///
/// A skeleton that mirrors the real row (short left block, two text lines) so the
/// screen does not jump when data lands. One slow breath on the whole block, not a
/// shimmer per line — the point is "working", not "look at me".
class LoadingState extends StatefulWidget {
  const LoadingState({
    super.key,
    this.rows = 4,
    this.label,
    this.rowHeight = 44,
  });

  final int rows;
  final String? label;
  final double rowHeight;

  @override
  State<LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<LoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final Animation<double> _fade = Tween<double>(
    begin: 0.45,
    end: 0.9,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(widget.label!, style: text.supporting),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        FadeTransition(
          opacity: _fade,
          child: Column(
            children: List.generate(widget.rows, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: SizedBox(
                  height: widget.rowHeight,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 12,
                        decoration: BoxDecoration(
                          color: c.outline,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 12,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: c.outline,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FractionallySizedBox(
                              widthFactor: 0.45,
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: c.outline,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
