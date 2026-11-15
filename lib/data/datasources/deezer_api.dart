import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/repositories/song_repository.dart';

/// The Deezer API's public, keyless part: track search and a track by id.
///
/// About 50 calls per 5 seconds at most. Its preview links are signed and
/// expire after about 15 minutes, hence [track] to get a fresh one before
/// playing. https://developers.deezer.com/api
class DeezerApi {
  DeezerApi([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;

  static const _timeout = Duration(seconds: 10);

  /// The raw `data` of a track search for [term].
  Future<List<Map<String, dynamic>>> searchTracks(
    String term, {
    int limit = 25,
  }) async {
    final body = await _get('/search', {'q': term, 'limit': '$limit'});
    final data = body['data'];
    if (data is! List) throw const SongCatalogException('Deezer: no data');
    return data.cast<Map<String, dynamic>>();
  }

  /// The raw track [id].
  Future<Map<String, dynamic>> track(String id) => _get('/track/$id', null);

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String>? query,
  ) async {
    final uri = Uri.https('api.deezer.com', path, query);
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(_timeout);
    } catch (e) {
      throw SongCatalogException('Deezer network: $e');
    }
    if (response.statusCode != 200) {
      throw SongCatalogException('Deezer HTTP ${response.statusCode}');
    }
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } catch (e) {
      throw SongCatalogException('Deezer bad response: $e');
    }
    // Errors come back as 200 with an "error" object.
    if (body['error'] != null) {
      throw SongCatalogException('Deezer error: ${body['error']}');
    }
    return body;
  }
}
