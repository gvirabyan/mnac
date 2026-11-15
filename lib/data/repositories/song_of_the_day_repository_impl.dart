import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/song.dart';
import '../../domain/repositories/song_repository.dart';
import '../models/song_model.dart';

/// Reads the `song_days` collection: one document per day, its id and `day`
/// field the date as "yyyy-mm-dd". The owner sets it from the debug build,
/// `tool/set_song.js` or the console; the security rules let apps read it
/// and write only a well-formed iTunes song.
///
/// The day is the phone's own date, so a song set for the 16th starts at
/// midnight wherever the listener is.
class SongOfTheDayRepositoryImpl implements SongOfTheDayRepository {
  SongOfTheDayRepositoryImpl([FirebaseFirestore? firestore])
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static String dayKey(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-'
      '${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';

  @override
  Stream<Song?> watchFor(DateTime day) => _firestore
      .collection('song_days')
      .where('day', isLessThanOrEqualTo: dayKey(day))
      .orderBy('day', descending: true)
      .limit(1)
      .snapshots()
      // Offline before the first answer, an empty cache means "not known
      // yet", not "no song"; wait for the server instead of saying none.
      .where((s) => !(s.metadata.isFromCache && s.docs.isEmpty))
      .map((s) {
        final doc = s.docs.firstOrNull;
        return doc == null ? null : SongModel.fromDoc(doc.data());
      });

  @override
  Future<void> setFor(DateTime day, Song song) {
    final key = dayKey(day);
    return _firestore.collection('song_days').doc(key).set({
      ...SongModel.toDoc(key, song),
      'setAt': FieldValue.serverTimestamp(),
    });
  }
}
