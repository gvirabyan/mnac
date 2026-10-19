import '../entities/announcement.dart';

/// Read-only source of the broadcast push history. Implemented in the data
/// layer.
abstract interface class AnnouncementsRepository {
  /// The most recent [limit] sent announcements, newest first. Emits again
  /// whenever a new one is sent; serves the last copy while offline.
  Stream<List<Announcement>> watchRecent({int limit});

  /// The newest sent announcement, or null when there is none; re-emitted
  /// whenever it changes. Costs a single document read, unlike
  /// [watchRecent] — meant for an always-visible marker.
  Stream<Announcement?> watchLatest();
}
