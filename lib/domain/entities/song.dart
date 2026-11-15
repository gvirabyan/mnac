/// Where a [Song] comes from: the catalog it was found in, which also plays
/// its preview and holds the full song.
enum SongSource {
  appleMusic('appleMusic'),
  deezer('deezer');

  const SongSource(this.key);

  /// Stored in the `source` field of a `song_days` document.
  final String key;

  /// Unknown or missing keys read as Apple Music, the first source.
  static SongSource fromKey(String? key) =>
      values.firstWhere((s) => s.key == key, orElse: () => appleMusic);
}

/// A song from a music catalog (iTunes or Deezer), as far as the app needs
/// it: what to show, a short preview to play and a link to the full song.
class Song {
  const Song({
    required this.source,
    required this.trackId,
    required this.title,
    required this.artist,
    this.artworkUrl,
    this.previewUrl,
    this.storeUrl,
  });

  final SongSource source;

  /// The catalog's own id for the track; stable across searches.
  final String trackId;
  final String title;
  final String artist;

  /// Square cover art.
  final String? artworkUrl;

  /// A 30-second clip, or null for the rare track with none. Deezer's links
  /// expire within minutes, so play via
  /// SongCatalogRepository.freshPreviewUrl, never this link directly.
  final String? previewUrl;

  /// The song's page in the catalog's app, where the full song plays.
  final String? storeUrl;

  /// Unique across catalogs, which number their tracks independently.
  String get id => '${source.key}:$trackId';

  bool get canPreview => previewUrl != null;

  @override
  bool operator ==(Object other) => other is Song && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
