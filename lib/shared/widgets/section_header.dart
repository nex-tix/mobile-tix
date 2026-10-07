import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A section inside a screen: heading, optional supporting line, optional action on
/// the right. Space above a heading always exceeds the space below it, so a scan
/// down the left edge of the screen reads as groups rather than one column.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.topSpace = AppSpacing.xl + 4,
    this.bottomSpace = AppSpacing.sm,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double topSpace;
  final double bottomSpace;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return Padding(
      padding: EdgeInsets.only(top: topSpace, bottom: bottomSpace),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: text.section),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: text.supporting),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
