import 'dart:ui';

/// Languages the UI is translated into.
enum AppLanguage {
  hy('hy'),
  ru('ru'),
  en('en');

  const AppLanguage(this.id);
  final String id;

  Locale get locale => Locale(id);

  /// The language a fresh install starts in: the first of the phone's
  /// preferred languages the app is translated into, English otherwise.
  ///
  /// Never Armenian by default — only a phone actually set to Armenian gets
  /// it. AdMob does not support Armenian, and an English or Russian phone
  /// (an ad reviewer's included) must open on a language ads may run beside.
  static AppLanguage fromLocales(List<Locale> locales) {
    for (final locale in locales) {
      final match = tryFromId(locale.languageCode);
      if (match != null) return match;
    }
    return AppLanguage.en;
  }

  /// Parses a stored id; null for a missing or unknown one.
  static AppLanguage? tryFromId(String? id) {
    for (final l in values) {
      if (l.id == id) return l;
    }
    return null;
  }
}
