import '../../domain/entities/song.dart';

/// Converts [Song] from the iTunes and Deezer APIs' results and to and from
/// a `song_days` document:
///
/// ```
/// song_days/2026-11-16 {
///   day: "2026-11-16", source: "appleMusic" | "deezer",
///   trackId: "1440818663", title: "...", artist: "...",
///   artworkUrl: "...", previewUrl: "...", storeUrl: "...", setAt: <time>
/// }
/// ```
///
/// `tool/set_song.js` writes the same shape, and firestore.rules checks it.
abstract final class SongModel {
  /// A song from one item of an iTunes search's `results`, or null when the
  /// item is not a usable song (no id, title or artist).
  static Song? fromItunes(Map<String, dynamic> json) {
    final id = json['trackId'];
    final title = json['trackName'];
    final artist = json['artistName'];
    if (id == null || title is! String || artist is! String) return null;
    return Song(
      source: SongSource.appleMusic,
      trackId: '$id',
      title: title,
      artist: artist,
      artworkUrl: _sharperArtwork(json['artworkUrl100'] as String?),
      previewUrl: json['previewUrl'] as String?,
      storeUrl: json['trackViewUrl'] as String?,
    );
  }

  /// The 100px artwork link asks for 100px; the same link with a larger size
  /// in it serves a larger image, which stays sharp on dense screens.
  static String? _sharperArtwork(String? url) =>
      url?.replaceFirst('100x100bb', '200x200bb');

  /// A song from one Deezer track, or null when it is not a usable song (no
  /// id, title or artist, or not playable in this region).
  static Song? fromDeezer(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final artist = (json['artist'] as Map?)?['name'];
    if (id == null || title is! String || artist is! String) return null;
    if (json['readable'] == false) return null;
    return Song(
      source: SongSource.deezer,
      trackId: '$id',
      title: title,
      artist: artist,
      artworkUrl: (json['album'] as Map?)?['cover_medium'] as String?,
      previewUrl: deezerPreview(json),
      storeUrl: json['link'] as String?,
    );
  }

  /// The track's preview link; Deezer sends "" for a track with none.
  static String? deezerPreview(Map<String, dynamic> json) {
    final preview = json['preview'];
    return preview is String && preview.isNotEmpty ? preview : null;
  }

  /// Null when the document lacks an id, title or artist.
  static Song? fromDoc(Map<String, dynamic> data) {
    final id = data['trackId'];
    final title = data['title'];
    final artist = data['artist'];
    if (id == null || title is! String || artist is! String) return null;
    return Song(
      source: SongSource.fromKey(data['source'] as String?),
      trackId: '$id',
      title: title,
      artist: artist,
      artworkUrl: data['artworkUrl'] as String?,
      previewUrl: data['previewUrl'] as String?,
      storeUrl: data['storeUrl'] as String?,
    );
  }

  /// The document's fields, all but `setAt`, which the writer stamps.
  static Map<String, dynamic> toDoc(String day, Song song) => {
        'day': day,
        'source': song.source.key,
        'trackId': song.trackId,
        'title': song.title,
        'artist': song.artist,
        'artworkUrl': song.artworkUrl,
        'previewUrl': song.previewUrl,
        'storeUrl': song.storeUrl,
      };
}
