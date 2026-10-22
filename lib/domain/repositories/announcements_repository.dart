import '../../core/l10n/app_language.dart';
import '../entities/announcement.dart';

/// Read-only source of the broadcast push history. Implemented in the data
/// layer.
abstract interface class AnnouncementsRepository {
  /// The most recent [limit] announcements sent to everyone or to
  /// [language] alone, newest first. Emits the copy saved on the phone at
  /// once, then again with whatever is new on the server; offline, only the
  /// saved copy. Fetches anew each time it is listened to.
  Stream<List<Announcement>> watchRecent(AppLanguage language, {int limit});

  /// The newest announcement sent to everyone or to [language] alone, or
  /// null when there is none; re-emitted whenever it changes. Costs a single
  /// document read, unlike [watchRecent] — meant for an always-visible
  /// marker.
  Stream<Announcement?> watchLatest(AppLanguage language);
}
