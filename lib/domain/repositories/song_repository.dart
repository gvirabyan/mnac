import '../entities/song.dart';

/// Searches the music catalogs. Implemented in the data layer over the
/// iTunes Search API and the Deezer API.
abstract interface class SongCatalogRepository {
  /// Songs matching [query], best match first; empty when nothing matches.
  /// Throws [SongCatalogException] when the catalog cannot be reached.
  Future<List<Song>> search(String query);

  /// A link to [song]'s preview that plays now; null when it has none.
  /// Deezer's links expire within minutes, so this asks Deezer again; an
  /// iTunes link lasts and comes back as is. Throws [SongCatalogException]
  /// when the catalog cannot be reached.
  Future<String?> freshPreviewUrl(Song song);
}

/// The catalog could not be reached or answered with something unreadable.
class SongCatalogException implements Exception {
  const SongCatalogException(this.message);
  final String message;

  @override
  String toString() => 'SongCatalogException: $message';
}

/// The song of the day, the same for everyone. Implemented in the data layer
/// over Firestore.
abstract interface class SongOfTheDayRepository {
  /// The song for the calendar day of [day]: the one set for that day, or
  /// else the latest set before it, so a song stays until the next one.
  /// Null while no song was ever set. Emits again when it changes.
  Stream<Song?> watchFor(DateTime day);

  /// Makes [song] everyone's song for the calendar day of [day]. Only the
  /// debug build offers this; see SongOfTheDayScreen.
  Future<void> setFor(DateTime day, Song song);
}
