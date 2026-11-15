import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../domain/entities/song.dart';
import '../song_player_controller.dart';

/// Round play / pause button for [song]'s preview, in the accent. Shows a
/// spinner while the preview loads and a warning sign after it failed to
/// play; a tap then tries again. Disabled for a song with no preview.
class SongPlayButton extends ConsumerWidget {
  const SongPlayButton({super.key, required this.song, this.size = 36});

  final Song song;

  /// Diameter of the circle; the tap target stays at least 40.
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final playback = ref.watch(songPlayerProvider);
    final mine = playback.songId == song.id;
    final playing = playback.isPlaying(song);
    final loading = playback.isLoading(song) && !playing;
    final failed = mine && playback.failed;

    final Widget icon;
    if (loading) {
      icon = SizedBox.square(
        dimension: size * 0.42,
        child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
      );
    } else {
      icon = Icon(
        failed
            ? Icons.error_outline_rounded
            : playing
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
        size: size * 0.6,
        color: failed ? scheme.error : scheme.primary,
      );
    }

    return Semantics(
      button: true,
      label: failed
          ? AppStrings.songPlayFailed
          : playing
              ? AppStrings.songPause
              : AppStrings.songPlay,
      child: InkResponse(
        onTap: song.canPreview
            ? () => ref.read(songPlayerProvider.notifier).toggle(song)
            : null,
        radius: size / 2 + 6,
        child: SizedBox.square(
          dimension: size < 40 ? 40 : size,
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary
                    .withValues(alpha: song.canPreview ? 0.16 : 0.06),
              ),
              alignment: Alignment.center,
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}

/// The song's cover, rounded, with a music note while it loads or when
/// there is none.
class SongArtwork extends StatelessWidget {
  const SongArtwork({super.key, required this.song, this.size = 44});

  final Song song;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.onSurface.withValues(alpha: 0.06),
      child: Icon(
        Icons.music_note_rounded,
        size: size * 0.5,
        color: scheme.onSurfaceVariant,
      ),
    );
    final url = song.artworkUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.2),
      child: SizedBox.square(
        dimension: size,
        child: url == null
            ? placeholder
            : Image.network(
                url,
                fit: BoxFit.cover,
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                errorBuilder: (_, _, _) => placeholder,
                frameBuilder: (_, child, frame, sync) =>
                    frame == null && !sync ? placeholder : child,
              ),
      ),
    );
  }
}

/// "Open in Apple Music" or "Open in Deezer", by where [song] comes from.
String openInStoreLabel(Song song) => switch (song.source) {
      SongSource.appleMusic => AppStrings.songOpenInAppleMusic,
      SongSource.deezer => AppStrings.songOpenInDeezer,
    };

/// Opens [song] in Apple Music or Deezer. Both catalogs' terms ask for this
/// link next to every place a preview plays.
Future<void> openSongInStore(Song song) async {
  final url = song.storeUrl;
  if (url == null) return;
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
