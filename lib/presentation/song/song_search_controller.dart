import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/song.dart';

/// The search on the song screen: null before anything is typed, then the
/// results of the latest query (loading, found, or failed).
///
/// Waits for the typing to pause before it asks the catalog, which allows
/// only about 20 searches a minute, and drops the answer to a query the user
/// has typed past.
final songSearchProvider =
    NotifierProvider.autoDispose<SongSearchController, AsyncValue<List<Song>>?>(
  SongSearchController.new,
);

class SongSearchController extends Notifier<AsyncValue<List<Song>>?> {
  static const _debounce = Duration(milliseconds: 450);
  static const _minLength = 2;

  Timer? _timer;
  String _query = '';

  @override
  AsyncValue<List<Song>>? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  void setQuery(String text) {
    final query = text.trim();
    if (query == _query) return;
    _query = query;
    _timer?.cancel();
    if (query.length < _minLength) {
      state = null;
      return;
    }
    state = const AsyncLoading();
    _timer = Timer(_debounce, () => _run(query));
  }

  /// Runs the current query again, after a failure.
  void retry() {
    if (_query.length < _minLength) return;
    state = const AsyncLoading();
    _run(_query);
  }

  Future<void> _run(String query) async {
    final result = await AsyncValue.guard(
      () => ref.read(songCatalogRepositoryProvider).search(query),
    );
    // Typed on since, or the screen was closed: this answer is stale.
    if (!ref.mounted || query != _query) return;
    state = result;
  }
}
