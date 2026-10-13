import 'package:flutter/material.dart';

/// The palette, as theme-bound tokens.
///
/// Widgets read colours through `context.colors`, so the light and dark schemes are
/// the same design, resolved twice — never a widget with a hardcoded hex.
///
/// Ground is a warm off-white and ink is a cool slate: the app reads as paper +
/// stamp ink, which is the world this product actually lives in. Status colours are
/// the only saturated accents on a screen, so a verdict can be found from arm's
/// length before any word is read.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.ground,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceField,
    required this.onField,
    required this.onFieldMuted,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.onInk,
    required this.outline,
    required this.outlineStrong,
    required this.primary,
    required this.primaryPressed,
    required this.onPrimary,
    required this.primaryTint,
    required this.onPrimaryTint,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryTint,
    required this.onSecondaryTint,
    required this.valid,
    required this.validTint,
    required this.used,
    required this.usedTint,
    required this.expired,
    required this.expiredTint,
    required this.notYet,
    required this.notYetTint,
    required this.cancelled,
    required this.cancelledTint,
    required this.notFound,
    required this.notFoundTint,
    required this.scrim,
  });

  /// Screen background.
  final Color ground;

  /// Raised paper: sheets, the login panel, list rows that need separation.
  final Color surface;

  /// Sunken paper: input fields, segmented tracks, quiet blocks.
  final Color surfaceAlt;

  /// The instrument field: the scanner's camera area. Dark in both schemes, because
  /// a viewfinder is a dark surface by physics, not by taste.
  final Color surfaceField;
  final Color onField;
  final Color onFieldMuted;

  final Color ink;
  final Color inkMuted;

  /// Decorative only — icons, hairline rules, disabled fills. Never text.
  final Color inkFaint;
  final Color onInk;

  final Color outline;
  final Color outlineStrong;

  final Color primary;
  final Color primaryPressed;
  final Color onPrimary;
  final Color primaryTint;
  final Color onPrimaryTint;

  final Color secondary;
  final Color onSecondary;
  final Color secondaryTint;
  final Color onSecondaryTint;

  final Color valid;
  final Color validTint;
  final Color used;
  final Color usedTint;
  final Color expired;
  final Color expiredTint;

  /// Tiket yang belum masuk masa berlaku: menunggu tanggalnya, bukan ditolak.
  final Color notYet;
  final Color notYetTint;
  final Color cancelled;
  final Color cancelledTint;
  final Color notFound;
  final Color notFoundTint;

  final Color scrim;

  Color get amber => secondary;
  Color get amberDark => Color(0xFFD4B145);
  Color get dangerRed => primary;
  Color get emerald => valid;

  static const Color darkTeal = Color(0xFF2A363B);
  static const Color deepRed = Color(0xFFCF4647);
  static const Color gold = Color(0xFFF5D061);
  static const Color offWhite = Color(0xFFF8F6F6);

  static const AppColors light = AppColors(
    ground: Color(0xFFF3F5F7),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFE4E8EB),
    surfaceField: Color(0xFF1E272B),
    onField: Color(0xFFF8F6F6),
    onFieldMuted: Color(0xFFA3B1B7),
    ink: Color(0xFF1E272B),
    inkMuted: Color(0xFF67777E),
    inkFaint: Color(0xFF98A6AC),
    onInk: Color(0xFFFFFFFF),
    outline: Color(0xFFE0E5E8),
    outlineStrong: Color(0xFFC7D0D4),
    primary: Color(0xFFCF4647),
    primaryPressed: Color(0xFFB83A3B),
    onPrimary: Color(0xFFFFFFFF),
    primaryTint: Color(0x1ACF4647),
    onPrimaryTint: Color(0xFFCF4647),
    secondary: Color(0xFFD4A826),
    onSecondary: Color(0xFFFFFFFF),
    secondaryTint: Color(0x26F5D061),
    onSecondaryTint: Color(0xFF8A6B0A),
    valid: Color(0xFF10B981),
    validTint: Color(0x2610B981),
    used: Color(0xFFCF4647),
    usedTint: Color(0x26CF4647),
    expired: Color(0xFFF59E0B),
    expiredTint: Color(0x26F59E0B),
    notYet: Color(0xFF2F6FED),
    notYetTint: Color(0x262F6FED),
    cancelled: Color(0xFFEF4444),
    cancelledTint: Color(0x26EF4444),
    notFound: Color(0xFF6B7280),
    notFoundTint: Color(0x266B7280),
    scrim: Color(0x66000000),
  );

  static const AppColors dark = AppColors(
    ground: Color(0xFF2A363B),
    surface: Color(0xFF212B2F),
    surfaceAlt: Color(0xFF334147),
    surfaceField: Color(0xFF182023),
    onField: Color(0xFFF8F6F6),
    onFieldMuted: Color(0xFFA3B1B7),
    ink: Color(0xFFF8F6F6),
    inkMuted: Color(0xFFA3B1B7),
    inkFaint: Color(0xFF6B7E86),
    onInk: Color(0xFF2A363B),
    outline: Color(0xFF3E4E55),
    outlineStrong: Color(0xFF4C5E66),
    primary: Color(0xFFCF4647),
    primaryPressed: Color(0xFFB83A3B),
    onPrimary: Color(0xFFFFFFFF),
    primaryTint: Color(0x33CF4647),
    onPrimaryTint: Color(0xFFFFB3AF),
    secondary: Color(0xFFF5D061),
    onSecondary: Color(0xFF2A363B),
    secondaryTint: Color(0x33F5D061),
    onSecondaryTint: Color(0xFFF5D061),
    valid: Color(0xFF2ECC71),
    validTint: Color(0x262ECC71),
    used: Color(0xFFCF4647),
    usedTint: Color(0x26CF4647),
    expired: Color(0xFFF5D061),
    expiredTint: Color(0x26F5D061),
    notYet: Color(0xFF7BA7F7),
    notYetTint: Color(0x267BA7F7),
    cancelled: Color(0xFFCF4647),
    cancelledTint: Color(0x26CF4647),
    notFound: Color(0xFFA3B1B7),
    notFoundTint: Color(0x26A3B1B7),
    scrim: Color(0x99000000),
  );

  @override
  AppColors copyWith({
    Color? ground,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceField,
    Color? onField,
    Color? onFieldMuted,
    Color? ink,
    Color? inkMuted,
    Color? inkFaint,
    Color? onInk,
    Color? outline,
    Color? outlineStrong,
    Color? primary,
    Color? primaryPressed,
    Color? onPrimary,
    Color? primaryTint,
    Color? onPrimaryTint,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryTint,
    Color? onSecondaryTint,
    Color? valid,
    Color? validTint,
    Color? used,
    Color? usedTint,
    Color? expired,
    Color? expiredTint,
    Color? notYet,
    Color? notYetTint,
    Color? cancelled,
    Color? cancelledTint,
    Color? notFound,
    Color? notFoundTint,
    Color? scrim,
  }) {
    return AppColors(
      ground: ground ?? this.ground,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surfaceField: surfaceField ?? this.surfaceField,
      onField: onField ?? this.onField,
      onFieldMuted: onFieldMuted ?? this.onFieldMuted,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      inkFaint: inkFaint ?? this.inkFaint,
      onInk: onInk ?? this.onInk,
      outline: outline ?? this.outline,
      outlineStrong: outlineStrong ?? this.outlineStrong,
      primary: primary ?? this.primary,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryTint: primaryTint ?? this.primaryTint,
      onPrimaryTint: onPrimaryTint ?? this.onPrimaryTint,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      secondaryTint: secondaryTint ?? this.secondaryTint,
      onSecondaryTint: onSecondaryTint ?? this.onSecondaryTint,
      valid: valid ?? this.valid,
      validTint: validTint ?? this.validTint,
      used: used ?? this.used,
      usedTint: usedTint ?? this.usedTint,
      expired: expired ?? this.expired,
      expiredTint: expiredTint ?? this.expiredTint,
      notYet: notYet ?? this.notYet,
      notYetTint: notYetTint ?? this.notYetTint,
      cancelled: cancelled ?? this.cancelled,
      cancelledTint: cancelledTint ?? this.cancelledTint,
      notFound: notFound ?? this.notFound,
      notFoundTint: notFoundTint ?? this.notFoundTint,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color f(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      ground: f(ground, other.ground),
      surface: f(surface, other.surface),
      surfaceAlt: f(surfaceAlt, other.surfaceAlt),
      surfaceField: f(surfaceField, other.surfaceField),
      onField: f(onField, other.onField),
      onFieldMuted: f(onFieldMuted, other.onFieldMuted),
      ink: f(ink, other.ink),
      inkMuted: f(inkMuted, other.inkMuted),
      inkFaint: f(inkFaint, other.inkFaint),
      onInk: f(onInk, other.onInk),
      outline: f(outline, other.outline),
      outlineStrong: f(outlineStrong, other.outlineStrong),
      primary: f(primary, other.primary),
      primaryPressed: f(primaryPressed, other.primaryPressed),
      onPrimary: f(onPrimary, other.onPrimary),
      primaryTint: f(primaryTint, other.primaryTint),
      onPrimaryTint: f(onPrimaryTint, other.onPrimaryTint),
      secondary: f(secondary, other.secondary),
      onSecondary: f(onSecondary, other.onSecondary),
      secondaryTint: f(secondaryTint, other.secondaryTint),
      onSecondaryTint: f(onSecondaryTint, other.onSecondaryTint),
      valid: f(valid, other.valid),
      validTint: f(validTint, other.validTint),
      used: f(used, other.used),
      usedTint: f(usedTint, other.usedTint),
      expired: f(expired, other.expired),
      expiredTint: f(expiredTint, other.expiredTint),
      notYet: f(notYet, other.notYet),
      notYetTint: f(notYetTint, other.notYetTint),
      cancelled: f(cancelled, other.cancelled),
      cancelledTint: f(cancelledTint, other.cancelledTint),
      notFound: f(notFound, other.notFound),
      notFoundTint: f(notFoundTint, other.notFoundTint),
      scrim: f(scrim, other.scrim),
    );
  }

  /// The Material roles the framework's own widgets read, resolved from this palette
  /// so a stock control (sheet, snackbar, dialog, ripple) never falls back to a
  /// default Material colour.
  ColorScheme toColorScheme(Brightness brightness) {
    return ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryTint,
      onPrimaryContainer: onPrimaryTint,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryTint,
      onSecondaryContainer: onSecondaryTint,
      tertiary: valid,
      onTertiary: brightness == Brightness.light ? surface : dark.surface,
      error: used,
      onError: brightness == Brightness.light ? Colors.white : dark.onPrimary,
      errorContainer: usedTint,
      onErrorContainer: used,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: inkMuted,
      surfaceContainerLowest: brightness == Brightness.light
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF1E272B),
      surfaceContainerLow: ground,
      surfaceContainer: surfaceAlt,
      surfaceContainerHigh: surfaceAlt,
      surfaceContainerHighest: surfaceAlt,
      outline: outlineStrong,
      outlineVariant: outline,
      shadow: scrim,
      scrim: scrim,
      inverseSurface: ink,
      onInverseSurface: onInk,
      inversePrimary: primaryTint,
    );
  }
}

/// `context.colors` — the app palette.
extension AppColorsX on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
