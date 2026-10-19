import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcements_repository.dart';
import '../models/announcement_model.dart';

/// Reads the `announcements` collection.
///
/// The `status == 'sent'` filter is not optional: the security rules only
/// let a client read sent documents, and Firestore rejects any query that
/// could return something the rules forbid.
class AnnouncementsRepositoryImpl implements AnnouncementsRepository {
  AnnouncementsRepositoryImpl([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Query<Map<String, dynamic>> _sentNewestFirst(int limit) => _firestore
      .collection('announcements')
      .where('status', isEqualTo: 'sent')
      .orderBy('sendAt', descending: true)
      .limit(limit);

  @override
  Stream<List<Announcement>> watchRecent({int limit = 50}) {
    return _sentNewestFirst(limit)
        .snapshots()
        .where(_isConclusive)
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              ?AnnouncementModel.fromDoc(doc.id, doc.data()),
          ],
        );
  }

  @override
  Stream<Announcement?> watchLatest() {
    return _sentNewestFirst(1).snapshots().where(_isConclusive).map((snapshot) {
      final doc = snapshot.docs.firstOrNull;
      return doc == null ? null : AnnouncementModel.fromDoc(doc.id, doc.data());
    });
  }

  /// Drops an empty snapshot served from the local cache: offline, before
  /// the server has ever been reached, that only means "nothing cached yet",
  /// and passing it on would claim there are no announcements at all.
  static bool _isConclusive(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      !(snapshot.metadata.isFromCache && snapshot.docs.isEmpty);
}
