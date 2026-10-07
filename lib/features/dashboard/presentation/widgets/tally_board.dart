import 'package:flutter/material.dart';

import '../../../../core/constants/ticket_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/gate_stats.dart';

/// The day's tally, drawn as one instrument rather than a row of metric cards.
///
/// The subject is the *split*: one bar, proportional, green through red, with the
/// numbers set on it. A grid of big-number cards would tell the supervisor the same
/// thing four times and hide the only relationship that matters — how much of the
/// traffic was turned away.
class TallyBoard extends StatelessWidget {
  const TallyBoard({super.key, required this.stats});

  final GateStats stats;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText.of(context);
    final refused = stats.refused;
    final maxReason = stats.reasons.values.fold<int>(
      1,
      (a, b) => a > b ? a : b,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: Text('MASUK', style: text.label)),
            Text(
              Fmt.count(stats.entered),
              style: text.tally.copyWith(fontSize: 38),
            ),
            const SizedBox(width: 5),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                'tiket',
                style: text.supporting.copyWith(fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: stats.valid * 100,
                  child: ColoredBox(color: c.valid),
                ),
                if (refused > 0)
                  Expanded(
                    flex: refused * 100,
                    child: ColoredBox(color: c.used),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _Legend(
              color: c.valid,
              word: 'Valid',
              value:
                  '${stats.valid} · ${Fmt.percent(stats.valid, stats.entered)}',
            ),
            const Spacer(),
            _Legend(
              color: c.used,
              word: 'Ditolak',
              value: '$refused · ${Fmt.percent(refused, stats.entered)}',
              alignEnd: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const Divider(height: 1, thickness: 1),
        for (final status in _reasonOrder) ...[
          _ReasonRow(
            status: status,
            count: stats.reasons[status] ?? 0,
            maxCount: maxReason,
          ),
          if (status != _reasonOrder.last)
            const Divider(height: 1, thickness: 1),
        ],
      ],
    );
  }

  static const List<TicketStatus> _reasonOrder = [
    TicketStatus.alreadyUsed,
    TicketStatus.expired,
    TicketStatus.notFound,
    TicketStatus.cancelled,
  ];
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.word,
    required this.value,
    this.alignEnd = false,
  });

  final Color color;
  final String word;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (alignEnd) ...[
          Text(value, style: text.chip.copyWith(fontSize: 12.5)),
          const SizedBox(width: 8),
        ],
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(word, style: text.supporting.copyWith(fontSize: 12.5)),
        if (!alignEnd) ...[
          const SizedBox(width: 8),
          Text(value, style: text.chip.copyWith(fontSize: 12.5)),
        ],
      ],
    );
  }
}

/// One refusal reason, with a proportion rule instead of a percentage column: the
/// length of the rule is the share, so the rows can be compared without reading.
class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.status,
    required this.count,
    required this.maxCount,
  });

  final TicketStatus status;
  final int count;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText.of(context);
    final share = maxCount == 0 ? 0.0 : count / maxCount;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 1),
      child: Row(
        children: [
          SizedBox(
            width: 108,
            child: Text(
              status.shortLabel,
              style: text.body.copyWith(
                fontSize: 14,
                color: count == 0 ? c.inkMuted : c.ink,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: share,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: status.ink(c),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 26,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: text.bodyStrong.copyWith(
                fontSize: 15,
                color: count == 0 ? c.inkMuted : c.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
