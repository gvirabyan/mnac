/// Animation duration tokens.
///
/// Centralizing durations keeps motion consistent and makes it easy to honor
/// the user's selected animation level (see [AppSettings.animationLevel]).
abstract final class AppDurations {
  AppDurations._();

  static const Duration instant = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 240);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 650);
  static const Duration celebratory = Duration(milliseconds: 1200);

  /// Live countdown tick interval.
  static const Duration tick = Duration(seconds: 1);

  /// How often a new motivational quote rotates in.
  static const Duration quoteRotation = Duration(seconds: 12);
}
