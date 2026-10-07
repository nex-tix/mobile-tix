/// Spacing, radius, size, and motion tokens.
///
/// One scale for the whole app. Screens never invent a 13 or a 27; they pick the
/// nearest step so that vertical rhythm stays consistent across features.
class AppSpacing {
  const AppSpacing._();

  // Space scale (multiples of 4, as the brief pins).
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  /// Horizontal padding for screen content.
  static const double page = 20;

  /// Horizontal padding inside sheets and cards.
  static const double inset = 20;

  // Radii.
  static const double radiusXs = 8;
  static const double radiusSm = 12;
  static const double radiusMd = 14;
  static const double radiusLg = 16;
  static const double radiusXl = 18;
  static const double radiusSheet = 24;

  // Control sizes.
  static const double control = 52; // primary button height
  static const double controlSm = 44;
  static const double touchTarget = 48;
  static const double appBar = 60;
  static const double divider = 1;

  // Motion. One authored moment per screen; everything else is quiet.
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 340);
  static const Duration stampPress = Duration(milliseconds: 280);

  /// How long a VALID verdict stays on screen before the sheet retracts itself.
  static const Duration verdictDwell = Duration(milliseconds: 4200);
}
