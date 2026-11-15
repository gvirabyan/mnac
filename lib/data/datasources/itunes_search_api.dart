import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/repositories/song_repository.dart';

/// The iTunes Search API: free, with no key or sign-up.
///
/// Its terms: about 20 calls a minute at most (the search screen waits for
/// the typing to stop and caches answers, see SongCatalogRepositoryImpl), and
/// every preview played must sit next to a link to the song in the store.
/// https://performance-partners.apple.com/resources/documentation/itunes-store-web-service-search-api/
class ItunesSearchApi {
  ItunesSearchApi([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;

  static const _timeout = Duration(seconds: 10);

  /// The US store: the widest catalog of Armenian and Russian songs among
  /// the stores tried, and its links open in the listener's own store.
  static const _country = 'US';

  /// The raw `results` of a song search for [term].
  Future<List<Map<String, dynamic>>> searchSongs(
    String term, {
    int limit = 25,
  }) async {
    final uri = Uri.https('itunes.apple.com', '/search', {
      'term': term,
      'media': 'music',
      'entity': 'song',
      'limit': '$limit',
      'country': _country,
    });
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(_timeout);
    } catch (e) {
      throw SongCatalogException('network: $e');
    }
    if (response.statusCode != 200) {
      throw SongCatalogException('HTTP ${response.statusCode}');
    }
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return (body['results'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw SongCatalogException('bad response: $e');
    }
  }
}
