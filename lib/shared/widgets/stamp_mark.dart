import 'package:flutter/material.dart';

import '../../core/constants/ticket_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// The signature move: a verdict arrives as an inked stamp pressed onto the sheet.
///
/// A rubber stamp is the one object this product's world actually owns, and it earns
/// its place here because it does a job no chip does: it is legible in one glance at
/// arm's length, it is impossible to confuse with a button, and the *press* is the
/// feedback — the operator sees the verdict land, not fade in.
///
/// Details that make it read as a stamp rather than a bordered box:
/// - a double frame (heavy outer rule, hairline inner rule),
/// - the whole mark set at a slight angle, as a hand would land it,
/// - a 1.5px ghost pass of the same mark at 12% ink — tiny misregistration, the way
///   a real stamp prints a second faint edge.
///
/// Kedaluwarsa is stamped as a filled mustard block instead of ink-on-paper, because
/// mustard at that luminance cannot hold text contrast; the mark changes form rather
/// than pretending it can.
class StampMark extends StatefulWidget {
  const StampMark({
    super.key,
    required this.status,
    this.subline,
    this.animate = true,
  });

  final TicketStatus status;

  /// Gate and time, printed under the word like the sub-line of a real stamp.
  final String? subline;

  final bool animate;

  @override
  State<StampMark> createState() => _StampMarkState();
}

class _StampMarkState extends State<StampMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppSpacing.stampPress,
    value: widget.animate ? 0 : 1,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 1.18,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo));

  late final Animation<double> _angle = Tween<double>(
    begin: -0.105,
    end: -0.043,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  late final Animation<double> _ink = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.4, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final status = widget.status;
    final mark = _MarkBody(status: status, subline: widget.subline);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Transform.rotate(
          angle: _angle.value,
          child: Transform.scale(
            scale: _scale.value,
            child: Opacity(
              opacity: _ink.value.clamp(0.0, 1.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ghost pass: the misregistration of a hand-pressed stamp.
                  if (status.stampIsInk)
                    Transform.translate(
                      offset: const Offset(1.5, -1.5),
                      child: Opacity(
                        opacity: 0.12,
                        child: IgnorePointer(child: mark),
                      ),
                    ),
                  // Impact: the first 30% of the press lifts a faint paper flash.
                  if (_controller.value < 0.3)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm + 6,
                        ),
                        border: Border.all(
                          color: status
                              .ink(c)
                              .withValues(
                                alpha: 0.30 * (1 - _controller.value / 0.3),
                              ),
                          width: 1.5,
                        ),
                      ),
                    ),
                  mark,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MarkBody extends StatelessWidget {
  const _MarkBody({required this.status, this.subline});

  final TicketStatus status;
  final String? subline;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText.of(context);
    final ink = status.ink(c);
    final filled = !status.stampIsInk;

    final wordColor = filled ? c.onSecondary : ink;
    final subColor = filled
        ? c.onSecondary.withValues(alpha: 0.78)
        : ink.withValues(alpha: 0.82);

    return Container(
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: filled ? c.secondary : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: filled ? null : Border.all(color: ink, width: 2.4),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          border: filled
              ? Border.all(color: c.onSecondary.withValues(alpha: 0.28))
              : Border.all(color: ink.withValues(alpha: 0.38)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status.label,
              style: text.stamp.copyWith(color: wordColor),
              maxLines: 1,
            ),
            if (subline != null) ...[
              const SizedBox(height: 5),
              Text(
                subline!,
                style: text.stampSub.copyWith(color: subColor),
                maxLines: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
