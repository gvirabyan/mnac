import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/announcement.dart';

/// Firestore document <-> [Announcement].
///
/// Documents are written by hand in the console as well as by the Cloud
/// Function, so a malformed one is skipped ([fromDoc] returns null) rather
/// than allowed to break the whole list.
abstract final class AnnouncementModel {
  AnnouncementModel._();

  static Announcement? fromDoc(String id, Map<String, dynamic> data) {
    final sendAt = data['sendAt'];
    if (sendAt is! Timestamp) return null;
    // Written by the Cloud Function at the moment of sending; absent on
    // pushes backfilled by hand, which fall back to the scheduled time.
    final sentAt = data['sentAt'];
    final title = data['title'];
    final body = data['body'];
    return Announcement(
      id: id,
      title: title is String ? title : '',
      body: body is String ? body : '',
      sentAt: (sentAt is Timestamp ? sentAt : sendAt).toDate(),
    );
  }
}
