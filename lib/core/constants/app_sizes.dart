/// Spacing, radius, and elevation tokens used across the app.
///
/// Keeping these in one place enforces a consistent, premium rhythm and
/// generous whitespace throughout the UI.
abstract final class AppSizes {
  AppSizes._();

  // Base spacing scale (4pt grid).
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // Screen padding.
  static const double screenPadding = 20;

  // Corner radii — soft, rounded, premium.
  static const double radiusSm = 12;
  static const double radiusMd = 20;
  static const double radiusLg = 28;
  static const double radiusXl = 36;
  static const double radiusPill = 999;

  // Card / surface elevation (soft shadows).
  static const double elevationLow = 2;
  static const double elevationMd = 8;
  static const double elevationHigh = 16;

  // Hero countdown sizing.
  static const double countdownRingSize = 280;
  static const double countdownRingStroke = 14;

  // Icon sizing.
  static const double iconSm = 18;
  static const double iconMd = 24;
  static const double iconLg = 32;
}
