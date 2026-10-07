import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_colors.dart';

/// The top app bar used by every tab.
///
/// A Material app bar (leading action, action slot, back behaviour intact), themed
/// to sit on the ground with a single hairline instead of a shadow. Two-line form:
/// a screen title, and an operational subtitle — which gate, which shift — because
/// on this app the context line is part of the wayfinding, not decoration.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.divider = true,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final bool divider;

  @override
  Size get preferredSize => Size.fromHeight(
    subtitle == null ? AppSpacing.appBar : AppSpacing.appBar + 8,
  );

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return AppBar(
      toolbarHeight: preferredSize.height,
      leading: leading,
      leadingWidth: leading == null ? null : 56,
      titleSpacing: leading == null ? AppSpacing.page : 0,
      shape: divider
          ? null
          : const Border(bottom: BorderSide(color: Colors.transparent)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: text.screenTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                subtitle!,
                style: text.supporting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      actions: trailing == null
          ? null
          : [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.page),
                child: trailing,
              ),
            ],
    );
  }
}

/// A 1px hairline with optional insets — the app's only divider.
class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.indent = 0,
    this.endIndent = 0,
    this.color,
  });

  final double indent;
  final double endIndent;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: AppSpacing.divider,
      thickness: AppSpacing.divider,
      indent: indent,
      endIndent: endIndent,
      color: color ?? context.colors.outline,
    );
  }
}
