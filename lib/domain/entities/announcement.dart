import '../../core/l10n/app_language.dart';

/// Title and body of an announcement in one language.
class AnnouncementText {
  const AnnouncementText({this.title = '', this.body = ''});

  final String title;
  final String body;

  bool get isEmpty => title.isEmpty && body.isEmpty;
}

/// One broadcast push, as kept in the history the app can show.
///
/// Every push sent to all users is also stored server-side (see
/// `functions/index.js`), so the history survives a dismissed banner, a
/// reinstall, or an install that happened after the push went out.
class Announcement {
  const Announcement({
    required this.id,
    required this.texts,
    required this.sentAt,
  });

  final String id;

  /// The text in each language it was written in; never holds an empty one.
  final Map<AppLanguage, AnnouncementText> texts;

  /// When the push actually went out (server time). Backfilled console
  /// pushes carry no send record and use the date entered by hand.
  final DateTime sentAt;

  /// Which languages stand in for a missing one, best first. Russian and
  /// English never fall back to Armenian: AdMob does not support it, and ads
  /// run beside the history in those languages. Must match `FALLBACKS` in
  /// `functions/index.js`, so the history shows the very text that was pushed.
  static const Map<AppLanguage, List<AppLanguage>> fallbacks = {
    AppLanguage.hy: [AppLanguage.hy, AppLanguage.ru, AppLanguage.en],
    AppLanguage.ru: [AppLanguage.ru, AppLanguage.en],
    AppLanguage.en: [AppLanguage.en, AppLanguage.ru],
  };

  /// What a user reading the app in [language] gets; null when there is
  /// nothing for them, in which case the announcement is not shown at all.
  AnnouncementText? textIn(AppLanguage language) {
    for (final l in fallbacks[language]!) {
      final text = texts[l];
      if (text != null) return text;
    }
    return null;
  }
}
