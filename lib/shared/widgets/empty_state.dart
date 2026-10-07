import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Nothing to show, and what to do about it.
///
/// Deliberately quiet: a bordered square holding one icon, a heading, one sentence,
/// and the action that changes the state. No illustration — an empty log is a normal
/// Tuesday for a gate that just opened, not an event worth a picture.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.topSpace = AppSpacing.xxxl + 8,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final double topSpace;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page,
        topSpace,
        AppSpacing.page,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: c.outline),
            ),
            child: Icon(icon, size: 24, color: c.inkMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: text.section),
          const SizedBox(height: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(message, style: text.supporting),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}
