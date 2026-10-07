import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum AppButtonVariant {
  /// One per screen: the action the operator came to take.
  primary,

  /// The alternate way to do the same job.
  secondary,

  /// No container at all — sheet dismissals, "ganti", inline actions.
  quiet,

  /// Refusal. Used for "Tolak masuk" and destructive settings.
  danger,
}

/// The app's button.
///
/// Height, radius, and type come from the tokens, so a filled action and an outlined
/// one sit at exactly the same height in a row of two. Loading keeps the label in
/// place and swaps the leading icon for a spinner — the operator never loses the word
/// for what they pressed.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.trailing,
    this.loading = false,
    this.expanded = true,
    this.height = AppSpacing.control,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final Widget? trailing;
  final bool loading;
  final bool expanded;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText.of(context);
    final enabled = onPressed != null && !loading;

    final foreground = switch (variant) {
      AppButtonVariant.primary || AppButtonVariant.danger => c.onPrimary,
      AppButtonVariant.secondary => c.ink,
      AppButtonVariant.quiet => c.primary,
    };

    final content = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 17,
            height: 17,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation(foreground),
              backgroundColor: foreground.withValues(alpha: 0.25),
            ),
          )
        else if (icon != null)
          Icon(icon, size: 19, color: foreground),
        if (loading || icon != null) const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: text.button.copyWith(
              fontSize:
                  variant == AppButtonVariant.primary ||
                      variant == AppButtonVariant.danger
                  ? 16
                  : 15.5,
              color: enabled ? foreground : null,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.xs),
          trailing!,
        ],
      ],
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    );

    final child = SizedBox(
      height: height,
      child: Center(child: content),
    );

    return switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          minimumSize: Size(expanded ? double.infinity : 0, height),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: shape,
        ),
        child: child,
      ),
      AppButtonVariant.danger => FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: c.used,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.surfaceAlt,
          disabledForegroundColor: c.inkFaint,
          minimumSize: Size(expanded ? double.infinity : 0, height),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: shape,
        ),
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          minimumSize: Size(expanded ? double.infinity : 0, height),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: shape,
        ),
        child: child,
      ),
      AppButtonVariant.quiet => TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          minimumSize: Size(expanded ? double.infinity : 0, height),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: shape,
        ),
        child: child,
      ),
    };
  }
}
