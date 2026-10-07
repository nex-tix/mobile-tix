import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// The theme, resolved twice from one palette.
///
/// Material 3 owns structure and interaction; this file is where the brand enters:
/// the two faces, the warm ground, the red that only ever means "this control
/// acts" or "ticket was refused", and the flat paper surfaces (elevation is a hairline
/// and a tonal step here, never a drop shadow).
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(AppColors.light, Brightness.light);

  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final scheme = c.toColorScheme(brightness);
    final text = AppText.textTheme(c);
    const page = AppSpacing.page;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'DMSans',
      scaffoldBackgroundColor: c.ground,
      canvasColor: c.ground,
      textTheme: text,
      extensions: <ThemeExtension<dynamic>>[c],
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,

      // The parts we did not draw still carry the design: selection, caret, ripples.
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primary.withValues(alpha: 0.22),
        selectionHandleColor: c.primary,
      ),
      splashColor: c.primary.withValues(alpha: 0.06),
      highlightColor: c.primary.withValues(alpha: 0.04),
      hoverColor: c.primary.withValues(alpha: 0.05),

      appBarTheme: AppBarTheme(
        backgroundColor: c.ground,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: AppSpacing.appBar,
        titleSpacing: page,
        titleTextStyle: text.titleLarge,
        shape: Border(bottom: BorderSide(color: c.outline, width: 1)),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: c.primaryTint,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppText(c).navLabel
              .copyWith(color: selected ? c.onPrimaryTint : c.inkMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? c.primary : c.inkMuted,
          );
        }),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(
            const Size.fromHeight(AppSpacing.control),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? c.surfaceAlt
                : s.contains(WidgetState.pressed)
                ? c.primaryPressed
                : c.primary,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? c.inkFaint : c.onPrimary,
          ),
          overlayColor: WidgetStateProperty.all(
            c.onPrimary.withValues(alpha: 0.10),
          ),
          elevation: WidgetStateProperty.all(0),
          textStyle: WidgetStateProperty.all(AppText(c).button),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(
            const Size.fromHeight(AppSpacing.control),
          ),
          foregroundColor: WidgetStateProperty.all(c.ink),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.pressed) ? c.surfaceAlt : null,
          ),
          side: WidgetStateProperty.resolveWith(
            (s) => BorderSide(
              color: s.contains(WidgetState.disabled)
                  ? c.outline
                  : c.outlineStrong,
            ),
          ),
          elevation: WidgetStateProperty.all(0),
          textStyle: WidgetStateProperty.all(AppText(c).button),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(
            const Size(AppSpacing.touchTarget, AppSpacing.touchTarget),
          ),
          foregroundColor: WidgetStateProperty.all(c.primary),
          overlayColor: WidgetStateProperty.all(
            c.primary.withValues(alpha: 0.08),
          ),
          textStyle: WidgetStateProperty.all(AppText(c).button),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
        ),
      ),

      iconTheme: IconThemeData(color: c.ink, size: 22),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        hintStyle: AppText(c).body.copyWith(color: c.inkMuted),
        labelStyle: AppText(c).label,
        floatingLabelStyle: AppText(c).label.copyWith(color: c.primary),
        errorStyle: AppText(c).supporting
            .copyWith(color: c.used, fontWeight: FontWeight.w600),
        border: _fieldBorder(c.outline),
        enabledBorder: _fieldBorder(c.outline),
        focusedBorder: _fieldBorder(c.primary, width: 1.6),
        errorBorder: _fieldBorder(c.used),
        focusedErrorBorder: _fieldBorder(c.used, width: 1.6),
        disabledBorder: _fieldBorder(c.outline),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.surface,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: false,
        constraints: const BoxConstraints(maxWidth: 640),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusSheet),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: text.titleLarge,
        contentTextStyle: AppText(c).body.copyWith(color: c.inkMuted),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: AppText(c).body.copyWith(color: c.onInk),
        actionTextColor: c.secondary,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),

      dividerTheme: DividerThemeData(color: c.outline, thickness: 1, space: 1),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.outline,
        circularTrackColor: Colors.transparent,
        strokeWidth: 2.4,
      ),

      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(3.5),
        radius: const Radius.circular(2),
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.dragged) ? c.inkMuted : c.outlineStrong,
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.ink,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        ),
        textStyle: AppText(c).supporting.copyWith(color: c.onInk),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: c.inkMuted,
        textColor: c.ink,
        titleTextStyle: AppText(c).bodyStrong,
        subtitleTextStyle: AppText(c).supporting,
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
