import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/l10n/app_language.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcements_repository.dart';
import '../datasources/local_prefs_data_source.dart';
import '../models/announcement_model.dart';

/// Reads the `announcements` collection.
///
/// The status filter is not optional: the security rules only let a client
/// read sent documents, and Firestore rejects any query that could return
/// something the rules forbid. `sent` went to everyone, `sent_<id>` to one
/// language only, so each language asks for those two.
///
/// The history is kept on the phone ([LocalPrefsDataSource]) so that opening
/// it costs one query for what is new, not a re-read of the whole list —
/// Firestore bills every document a fresh query returns, its own offline
/// cache notwithstanding.
class AnnouncementsRepositoryImpl implements AnnouncementsRepository {
  AnnouncementsRepositoryImpl(this._local, [FirebaseFirestore? firestore])
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final LocalPrefsDataSource _local;
  final FirebaseFirestore _firestore;

  /// Saved documents across all languages; enough for 50 per language.
  static const _maxSaved = 150;

  Query<Map<String, dynamic>> _sentNewestFirst(
    AppLanguage language,
    int limit,
  ) => _firestore
      .collection('announcements')
      .where('status', whereIn: ['sent', 'sent_${language.id}'])
      .orderBy('sendAt', descending: true)
      .limit(limit);

  @override
  Stream<List<Announcement>> watchRecent(
    AppLanguage language, {
    int limit = 50,
  }) async* {
    final saved = _SavedHistory.read(_local);
    final since = saved.since[language.id];
    if (since != null) yield saved.listFor(language, limit);

    final QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      // Only what was sent at or after the newest saved one; on a first
      // open, the latest [limit]. "At or after" rather than "after": two
      // pushes can share a send time, and a query that finds nothing is
      // billed as one read anyway.
      var query = _sentNewestFirst(language, limit);
      if (since != null) {
        query = query.where(
          'sendAt',
          isGreaterThanOrEqualTo: Timestamp.fromMillisecondsSinceEpoch(since),
        );
      }
      snapshot = await query.get(const GetOptions(source: Source.server));
    } catch (_) {
      // Offline: the saved copy stands, if there is one.
      if (since == null) rethrow;
      return;
    }

    for (final doc in snapshot.docs) {
      saved.put(doc.id, doc.data());
    }
    saved.since[language.id] = [
      ?since,
      for (final doc in snapshot.docs)
        if (doc.data()['sendAt'] case final Timestamp t)
          t.millisecondsSinceEpoch,
    ].fold(0, (a, b) => a > b ? a : b);
    await saved.write(_local, _maxSaved);
    yield saved.listFor(language, limit);
  }

  @override
  Stream<Announcement?> watchLatest(AppLanguage language) {
    return _sentNewestFirst(language, 1).snapshots().where(_isConclusive).map((
      snapshot,
    ) {
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

/// The history as saved on the phone: documents by id, in
/// [AnnouncementModel.toSaved] form, and per language the send time (epoch
/// ms) of the newest one fetched — where the next fetch starts.
class _SavedHistory {
  _SavedHistory(this.docs, this.since);

  final Map<String, Map<String, dynamic>> docs;
  final Map<String, int> since;

  static _SavedHistory read(LocalPrefsDataSource local) {
    try {
      final json = jsonDecode(local.readAnnouncementsJson() ?? '');
      return _SavedHistory({
        for (final doc in json['docs'] as List)
          (doc as Map<String, dynamic>)['id'] as String: doc,
      }, Map<String, int>.from(json['since'] as Map));
    } catch (_) {
      // Nothing saved yet, or unreadable: start over from the server.
      return _SavedHistory({}, {});
    }
  }

  void put(String id, Map<String, dynamic> data) =>
      docs[id] = AnnouncementModel.toSaved(id, data);

  List<Map<String, dynamic>> get _newestFirst =>
      docs.values.toList()
        ..sort((a, b) => (b['sendAt'] as int).compareTo(a['sendAt'] as int));

  /// What the query for [language] would return, newest first.
  List<Announcement> listFor(AppLanguage language, int limit) => [
    for (final doc in _newestFirst)
      if (doc['status'] == 'sent' || doc['status'] == 'sent_${language.id}')
        ?AnnouncementModel.fromSaved(doc),
  ].take(limit).toList();

  Future<void> write(LocalPrefsDataSource local, int max) =>
      local.writeAnnouncementsJson(
        jsonEncode({'docs': _newestFirst.take(max).toList(), 'since': since}),
      );
}
