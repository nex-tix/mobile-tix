import 'package:flutter/material.dart';
import 'package:mobile_tix/core/constants/app_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'app_top_bar.dart';

/// Label on the left, value on the right — the app's definition row.
///
/// Used by the scan verdict, the history detail, and the profile. Values are
/// right-aligned and tabular where they are codes or numbers, so a column of them
/// lines up like a printed receipt.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    this.dense = false,
    this.asCode = false,
    this.emphasise = false,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool dense;
  final bool asCode;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText.of(context);

    final valueStyle = asCode
        ? text.code
        : emphasise
        ? text.body.copyWith(fontWeight: FontWeight.w700)
        : text.body.copyWith(fontWeight: FontWeight.w500);

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: dense ? AppSpacing.xs + 2 : AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: text.label),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child:
                  valueWidget ??
                  Text(
                    value ?? '—',
                    textAlign: TextAlign.right,
                    style: valueStyle.copyWith(color: c.ink),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A stack of [DetailRow]s with hairlines between them — never around them.
class DetailList extends StatelessWidget {
  const DetailList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) rows.add(const AppDivider());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

/// A tappable settings/action row: icon, label, optional value, chevron.
class ActionRow extends StatelessWidget {
  const ActionRow({
    super.key,
    required this.icon,
    required this.label,
    this.detail,
    this.trailing,
    this.onTap,
    this.tone,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String? detail;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Overrides the icon and label colour (destructive actions).
  final Color? tone;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText.of(context);
    final color = tone ?? c.ink;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(icon, size: 20, color: tone ?? c.inkMuted),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: text.body.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (detail != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(detail!, style: text.supporting),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                trailing ??
                    Icon(
                      AppIcons.chevronRight,
                      size: 20,
                      color: c.inkFaint,
                    ),
              ],
            ),
          ),
        ),
        if (!last) const AppDivider(),
      ],
    );
  }
}
