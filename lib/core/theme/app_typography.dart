import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The app's own type vocabulary, bound to the active palette.
///
/// Menggunakan **DM Sans** untuk seluruh aplikasi — font geometric sans serif
/// yang bersih dan modern untuk readability optimal.
/// a gate actually needs in a hurry. Numerals are tabular everywhere, so a column of
/// times or tallies lines up like a printed log sheet instead of wobbling.
class AppText {
  const AppText(this.c);

  final AppColors c;

  static AppText of(BuildContext context) => AppText(context.colors);

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// 26/600 — one per screen.
  TextStyle get screenTitle => TextStyle(
    fontFamily: 'DMSans',
    fontSize: 26,
    height: 1.15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: c.ink,
  );

  /// 22/600 — sheet and dialog titles.
  TextStyle get sheetTitle => TextStyle(
    fontFamily: 'DMSans',
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: c.ink,
  );

  /// 17/600 — a section inside a screen.
  TextStyle get section => TextStyle(
    fontFamily: 'DMSans',
    fontSize: 17,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: c.ink,
  );

  /// 12/600, tracked, uppercase — a data label ("MASUK", "CHECKPOINT"), never a
  /// decorative eyebrow above a heading.
  TextStyle get label => TextStyle(
    fontFamily: 'DMSans',
    fontSize: 11.5,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.9,
    color: c.inkMuted,
  );

  TextStyle get body =>
      TextStyle(fontFamily: 'DMSans', fontSize: 15, height: 1.4, color: c.ink);

  TextStyle get bodyStrong => body.copyWith(fontWeight: FontWeight.w600);

  TextStyle get supporting => TextStyle(
    fontFamily: 'DMSans',
    fontSize: 13.5,
    height: 1.4,
    color: c.inkMuted,
  );

  /// 15/600 tracked, tabular — ticket serials.
  TextStyle get code => TextStyle(
    fontFamily: 'DMSans',
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    fontFeatures: _tabular,
    color: c.ink,
  );

  TextStyle get button => const TextStyle(
    fontFamily: 'DMSans',
    fontSize: 15.5,
    height: 1.1,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  TextStyle get navLabel => const TextStyle(
    fontFamily: 'DMSans',
    fontSize: 11.5,
    height: 1.1,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  /// Counters and tallies — condensed, tabular, tight.
  TextStyle get tally => TextStyle(
    fontFamily: 'DMSans',
    fontSize: 34,
    height: 1,
    fontWeight: FontWeight.w800,
    fontFeatures: _tabular,
    color: c.ink,
  );

  TextStyle get tallySmall => tally.copyWith(fontSize: 22);

  /// The stamped verdict. Slight positive tracking so the word reads as set type.
  TextStyle get stamp => const TextStyle(
    fontFamily: 'DMSans',
    fontSize: 34,
    height: 1,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.6,
    fontFeatures: _tabular,
  );

  /// The line under a stamp word: gate, date, mode.
  TextStyle get stampSub => const TextStyle(
    fontFamily: 'DMSans',
    fontSize: 14,
    height: 1.1,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    fontFeatures: _tabular,
  );

  /// 20/700 tracked, tabular — the active checkpoint, code chips.
  TextStyle get chip => const TextStyle(
    fontFamily: 'DMSans',
    fontSize: 13,
    height: 1.1,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    fontFeatures: _tabular,
  );

  /// Set on the Material roles so framework widgets inherit the family.
  static TextTheme textTheme(AppColors c) {
    final t = AppText(c);
    return TextTheme(
      displayLarge: t.tally,
      titleLarge: t.screenTitle,
      titleMedium: t.section,
      bodyLarge: t.body,
      bodyMedium: t.body,
      bodySmall: t.supporting,
      labelLarge: t.button,
      labelMedium: t.label,
      labelSmall: t.label,
    );
  }
}
