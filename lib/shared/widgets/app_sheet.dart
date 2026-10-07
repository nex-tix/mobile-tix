import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// The app's bottom sheet: 24px top radius, a 36px handle, 20px insets, keyboard and
/// gesture-inset aware. Every sheet in the app goes through this so the drag handle
/// and the padding are identical wherever the operator meets one.
class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.inset,
      0,
      AppSpacing.inset,
      AppSpacing.xl,
    ),
    this.showHandle = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showHandle;

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? barrierColor,
    bool useSafeArea = false,
    bool showHandle = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      useSafeArea: useSafeArea,
      barrierColor: barrierColor,
      // The sheet chrome (handle + insets) is the wrapper, not the caller's job:
      // passing the raw content here is what left every sheet flush to the edges.
      builder: (_) => AppSheet(showHandle: showHandle, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: AppSpacing.base,
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showHandle)
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.xs,
                ),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.outlineStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}
