import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/song.dart';

/// What the preview player is doing, for the strip on Home and the song
/// screen alike: one player for the whole app, so a preview started on one
/// shows as playing on the other.
@immutable
class SongPlayback {
  const SongPlayback({
    this.songId,
    this.playing = false,
    this.loading = false,
    this.progress = 0,
    this.failed = false,
  });

  /// The song loaded in the player; null when nothing is.
  final String? songId;
  final bool playing;

  /// Fetching the preview before the first sound.
  final bool loading;

  /// How far into the preview, 0 to 1.
  final double progress;

  /// The last attempt to play [songId] failed (offline, broken link).
  final bool failed;

  bool isPlaying(Song song) => songId == song.id && playing;
  bool isLoading(Song song) => songId == song.id && loading;

  SongPlayback copyWith({
    bool? playing,
    bool? loading,
    double? progress,
    bool? failed,
  }) =>
      SongPlayback(
        songId: songId,
        playing: playing ?? this.playing,
        loading: loading ?? this.loading,
        progress: progress ?? this.progress,
        failed: failed ?? this.failed,
      );
}

/// Plays the 30-second previews, one at a time, from either catalog.
///
/// The audio player is made on the first play, not before: Home shows the
/// strip on every launch, and most launches play nothing. Playback pauses
/// when the app goes to the background.
final songPlayerProvider =
    NotifierProvider<SongPlayerController, SongPlayback>(
  SongPlayerController.new,
);

class SongPlayerController extends Notifier<SongPlayback> {
  AudioPlayer? _player;
  final _subscriptions = <StreamSubscription<Object?>>[];
  AppLifecycleListener? _lifecycle;

  /// Bumped on every new song, so a slow load that finishes after the user
  /// moved on to another song cannot take over the state.
  int _generation = 0;

  @override
  SongPlayback build() {
    ref.onDispose(_release);
    return const SongPlayback();
  }

  AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer();
    _player = player;
    _subscriptions
      ..add(player.playerStateStream.listen((s) {
        if (state.songId == null) return;
        final done = s.processingState == ProcessingState.completed;
        state = state.copyWith(
          playing: s.playing && !done,
          loading: s.processingState == ProcessingState.loading ||
              s.processingState == ProcessingState.buffering,
          progress: done ? 0 : null,
        );
        // Rewound and stopped at the end, so the next tap plays it again.
        if (done) {
          player.pause();
          player.seek(Duration.zero);
        }
      }))
      ..add(player.positionStream.listen((position) {
        final total = player.duration;
        if (state.songId == null || total == null || total == Duration.zero) {
          return;
        }
        state = state.copyWith(
          progress: (position.inMilliseconds / total.inMilliseconds)
              .clamp(0.0, 1.0),
        );
      }));
    _lifecycle = AppLifecycleListener(onHide: () => _player?.pause());
    return player;
  }

  /// Plays [song]'s preview, or pauses it when it is the one playing.
  Future<void> toggle(Song song) async {
    if (!song.canPreview) return;
    final player = _ensurePlayer();

    if (state.songId == song.id && !state.failed) {
      if (state.playing) {
        await player.pause();
      } else {
        unawaited(player.play());
      }
      return;
    }

    final generation = ++_generation;
    state = SongPlayback(songId: song.id, loading: true);
    try {
      await player.stop();
      // Asked at each new play: a Deezer link saved earlier has expired.
      final url = await ref
          .read(songCatalogRepositoryProvider)
          .freshPreviewUrl(song);
      if (generation != _generation) return;
      if (url == null) throw const FormatException('no preview');
      await player.setUrl(url);
      if (generation != _generation) return;
      // Not awaited: play() completes only when playback stops.
      unawaited(player.play());
    } catch (_) {
      if (generation != _generation) return;
      state = SongPlayback(songId: song.id, failed: true);
    }
  }

  /// Stops whatever plays and unloads it.
  Future<void> stop() async {
    _generation++;
    state = const SongPlayback();
    await _player?.stop();
  }

  void _release() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _lifecycle?.dispose();
    _player?.dispose();
  }
}
