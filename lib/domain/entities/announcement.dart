/// One broadcast push, as kept in the history the app can show.
///
/// Every push sent to all users is also stored server-side (see
/// `functions/index.js`), so the history survives a dismissed banner, a
/// reinstall, or an install that happened after the push went out.
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.sentAt,
  });

  final String id;
  final String title;
  final String body;

  /// When the push actually went out (server time). Backfilled console
  /// pushes carry no send record and use the date entered by hand.
  final DateTime sentAt;
}

/// The newest sent announcement as one snapshot of the server saw it.
class LatestAnnouncement {
  const LatestAnnouncement(this.announcement, {required this.isConfirmed});

  /// Null when nothing has been sent yet.
  final Announcement? announcement;

  /// True once the snapshot is confirmed by the server; false while it is
  /// still the device's cached copy, which may be out of date.
  final bool isConfirmed;
}
