import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/app_router.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../domain/entities/song.dart';
import '../../song/song_of_the_day_controller.dart';
import '../../song/song_of_the_day_screen.dart';
import '../../song/song_player_controller.dart';
import '../../song/widgets/song_play_button.dart';

/// A slim "now playing" bar under the top row with the song of the day,
/// the same for everyone: play button, title and artist, and a link to the
/// full song in Apple Music or Deezer. Tapping the bar plays or pauses; a hairline
/// along its bottom edge shows the preview's progress.
///
/// Takes the gap between the top row and the countdown with it: while no
/// song is set (or it is still loading) it is just that gap, and the bar
/// slides in when the song arrives.
///
/// In the debug build (the owner's) the bar always shows and a tap opens
/// [SongOfTheDayScreen] to set the song for everyone; `kDebugMode` is a
/// constant, so release builds leave the picker out entirely.
class SongOfTheDayStrip extends ConsumerWidget {
  const SongOfTheDayStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(songOfTheDayProvider).value;
    return AnimatedSize(
      duration: AppDurations.medium,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: song == null && !kDebugMode
          ? const SizedBox(width: double.infinity, height: AppSizes.xl)
          : Padding(
              padding: const EdgeInsets.only(
                top: AppSizes.xs,
                bottom: AppSizes.lg,
              ),
              child: _Bar(song: song),
            ),
    );
  }
}

class _Bar extends ConsumerWidget {
  const _Bar({required this.song});

  /// Null only in the debug build, before any song is set.
  final Song? song;

  static const double _height = 36;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final song = this.song;
    final progress = ref.watch(songPlayerProvider.select(
      (p) => p.songId == song?.id ? p.progress : 0.0,
    ));

    final VoidCallback? onTap;
    if (kDebugMode) {
      onTap = () => Navigator.of(context).push(
            appPageRoute(const SongOfTheDayScreen()),
          );
    } else if (song != null && song.canPreview) {
      onTap = () => ref.read(songPlayerProvider.notifier).toggle(song);
    } else {
      onTap = null;
    }

    return Material(
      // The same faint shade as the day's text, so it reads over any photo.
      color: isDark
          ? Colors.black.withValues(alpha: 0.18)
          : Colors.white.withValues(alpha: 0.35),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        side: BorderSide(color: scheme.onSurface.withValues(alpha: 0.10)),
      ),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: _height,
          child: Stack(
            children: [
              Row(
                children: [
                  const SizedBox(width: AppSizes.xxs),
                  if (song != null)
                    SongPlayButton(song: song, size: 26)
                  else
                    SizedBox.square(
                      dimension: _height,
                      child: Icon(
                        Icons.music_note_rounded,
                        size: AppSizes.iconSm,
                        color: scheme.primary,
                      ),
                    ),
                  const SizedBox(width: AppSizes.xxs),
                  Expanded(
                    // One line, Telegram-style: the label in the accent,
                    // then the title, then the artist, which the ellipsis
                    // takes first.
                    child: Text.rich(
                      TextSpan(children: [
                        if (song == null)
                          TextSpan(
                            text: AppStrings.songNotChosen,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          )
                        else ...[
                          TextSpan(
                            text: '${AppStrings.songOfTheDay}  ·  ',
                            style: TextStyle(color: scheme.primary),
                          ),
                          TextSpan(
                            text: song.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: '  ·  ${song.artist}',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  if (song?.storeUrl != null)
                    IconButton(
                      tooltip: openInStoreLabel(song!),
                      iconSize: 16,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 40,
                        height: _height,
                      ),
                      color: scheme.onSurfaceVariant,
                      onPressed: () => openSongInStore(song!),
                      icon: const Icon(Icons.open_in_new_rounded),
                    )
                  else
                    const SizedBox(width: AppSizes.sm),
                ],
              ),
              if (progress > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 2,
                    color: scheme.primary,
                    backgroundColor: Colors.transparent,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
