/// Bundled asset paths used in more than one place.
abstract final class AppAssets {
  AppAssets._();

  /// Background shown wherever a soldier has no photo of their own: home,
  /// the share card, the home-screen widget. Replace the file to change it
  /// everywhere at once.
  static const String defaultBackground = 'assets/images/background.jpg';
}
