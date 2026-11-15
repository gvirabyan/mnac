import 'dart:async';

import '../../core/utils/armenian_transliteration.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/song_repository.dart';
import '../datasources/deezer_api.dart';
import '../datasources/itunes_search_api.dart';
import '../models/song_model.dart';

/// Song search over iTunes and Deezer at once, results merged.
///
/// A query typed in Armenian is spelled in Latin letters first, as both
/// catalogs write Armenian songs. The two are asked in parallel and their
/// lists interleaved, each one's best matches near the top; a song both have
/// shows once, from whichever list reached it first. Either catalog failing
/// leaves the other's results; only both failing is an error. Answers are
/// kept for the session, so going back to an earlier query costs no call.
class SongCatalogRepositoryImpl implements SongCatalogRepository {
  SongCatalogRepositoryImpl(this._itunes, this._deezer);

  final ItunesSearchApi _itunes;
  final DeezerApi _deezer;

  final _cache = <String, List<Song>>{};
  static const _maxCached = 30;

  @override
  Future<List<Song>> search(String query) async {
    var term = query.trim();
    if (ArmenianTransliteration.containsArmenian(term)) {
      term = ArmenianTransliteration.toLatin(term);
    }
    final key = term.toLowerCase();
    if (key.isEmpty) return const [];
    final cached = _cache[key];
    if (cached != null) return cached;

    final (itunes, deezer) = await (
      _attempt(() async => [
            for (final item in await _itunes.searchSongs(term))
              ?SongModel.fromItunes(item),
          ]),
      _attempt(() async => [
            for (final item in await _deezer.searchTracks(term))
              ?SongModel.fromDeezer(item),
          ]),
    ).wait;
    if (itunes == null && deezer == null) {
      throw const SongCatalogException('both catalogs failed');
    }
    final songs = _interleave(itunes ?? const [], deezer ?? const []);

    if (_cache.length >= _maxCached) _cache.remove(_cache.keys.first);
    _cache[key] = songs;
    return songs;
  }

  @override
  Future<String?> freshPreviewUrl(Song song) async {
    switch (song.source) {
      case SongSource.appleMusic:
        return song.previewUrl;
      case SongSource.deezer:
        return SongModel.deezerPreview(await _deezer.track(song.trackId));
    }
  }

  /// The list, or null when the catalog could not be reached or answered
  /// with something unexpected.
  static Future<List<Song>?> _attempt(Future<List<Song>> Function() f) async {
    try {
      return await f();
    } catch (_) {
      return null;
    }
  }

  static List<Song> _interleave(List<Song> a, List<Song> b) {
    final seen = <String>{};
    final out = <Song>[];
    void add(Song s) {
      if (seen.add(_sameSongKey(s))) out.add(s);
    }

    for (var i = 0; i < a.length || i < b.length; i++) {
      if (i < a.length) add(a[i]);
      if (i < b.length) add(b[i]);
    }
    return out;
  }

  /// Title and artist with case, spaces and punctuation dropped: the two
  /// catalogs spell the same song slightly differently ("Sirem-Sirem" and
  /// "Sirem Sirem").
  static String _sameSongKey(Song s) =>
      '${s.title}|${s.artist}'.toLowerCase().replaceAll(_noise, '');

  static final _noise = RegExp(r'[^\p{L}\p{N}|]', unicode: true);
}
