import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/di/providers.dart';
import '../../core/l10n/app_strings.dart';
import '../../domain/entities/song.dart';
import '../shared/widgets/gradient_scaffold.dart';
import '../shared/widgets/quiet_card.dart';
import 'song_of_the_day_controller.dart';
import 'song_player_controller.dart';
import 'song_search_controller.dart';
import 'widgets/song_play_button.dart';

/// Sets the song of the day for everyone: today's song (if any) on top, then
/// a search in the iTunes and Deezer catalogs. Any result can be previewed; tapping one
/// saves it as today's song and goes back to Home.
///
/// The owner's tool, in the debug build only: the strip on Home opens it
/// when `kDebugMode`, so release builds drop it and only play the song.
class SongOfTheDayScreen extends ConsumerStatefulWidget {
  const SongOfTheDayScreen({super.key});

  @override
  ConsumerState<SongOfTheDayScreen> createState() => _SongOfTheDayScreenState();
}

class _SongOfTheDayScreenState extends ConsumerState<SongOfTheDayScreen> {
  final _search = TextEditingController();

  @override
  void deactivate() {
    // Whatever was previewed here stops with the screen, the song just
    // picked included: Home starts quiet.
    if (ref.read(songPlayerProvider).songId != null) {
      ref.read(songPlayerProvider.notifier).stop();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _saving = false;

  Future<void> _pick(Song song) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(songOfTheDayRepositoryProvider)
          .setFor(DateTime.now(), song);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.songSaveFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = ref.watch(songOfTheDayProvider).value;
    final results = ref.watch(songSearchProvider);

    return GradientScaffold(
      appBar: AppBar(title: Text(AppStrings.songOfTheDay)),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (today != null) ...[
                _TodayCard(song: today),
                const SizedBox(height: AppSizes.md),
              ],
              TextField(
                controller: _search,
                autofocus: today == null,
                textInputAction: TextInputAction.search,
                onChanged: ref.read(songSearchProvider.notifier).setQuery,
                decoration: InputDecoration(
                  hintText: AppStrings.songSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: ValueListenableBuilder(
                    valueListenable: _search,
                    builder: (context, value, _) => value.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _search.clear();
                              ref
                                  .read(songSearchProvider.notifier)
                                  .setQuery('');
                            },
                          ),
                  ),
                ),
              ),
              SizedBox(
                height: AppSizes.sm,
                child: _saving
                    ? const Align(
                        alignment: Alignment.bottomCenter,
                        child: LinearProgressIndicator(minHeight: 2),
                      )
                    : null,
              ),
              Expanded(
                child: switch (results) {
                  null => _Message(AppStrings.songSearchPrompt),
                  AsyncError() => _Message(
                      AppStrings.songSearchFailed,
                      actionLabel: AppStrings.songRetry,
                      onAction: ref.read(songSearchProvider.notifier).retry,
                    ),
                  AsyncData(value: final songs) when songs.isEmpty =>
                    _Message(AppStrings.songNothingFound),
                  AsyncData(value: final songs) => ListView.separated(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.only(bottom: AppSizes.md),
                      itemCount: songs.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        indent: 44 + AppSizes.sm,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.06),
                      ),
                      itemBuilder: (context, i) => _ResultRow(
                        song: songs[i],
                        chosen: songs[i] == today,
                        onTap: () => _pick(songs[i]),
                      ),
                    ),
                  _ => const Align(
                      alignment: Alignment.topCenter,
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
                child: Text(
                  AppStrings.songPreviewNote,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Today's song: cover, title, play and a link to the full song.
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.song});
  final Song song;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return QuietCard(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.md,
        AppSizes.xs,
        AppSizes.xxs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.songOfTheDay,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.primary),
          ),
          const SizedBox(height: AppSizes.xs),
          Row(
            children: [
              SongArtwork(song: song, size: 56),
              const SizedBox(width: AppSizes.sm),
              Expanded(child: _TitleAndArtist(song: song, large: true)),
              SongPlayButton(song: song, size: 44),
            ],
          ),
          if (song.storeUrl != null)
            TextButton.icon(
              onPressed: () => openSongInStore(song),
              icon: const Icon(Icons.open_in_new_rounded,
                  size: AppSizes.iconSm),
              label: Text(openInStoreLabel(song)),
            )
          else
            const SizedBox(height: AppSizes.sm),
        ],
      ),
    );
  }
}

/// One search result: tap to make it today's song; the play button only
/// previews it.
class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.song,
    required this.chosen,
    required this.onTap,
  });

  final Song song;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      hint: AppStrings.songPick,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
          child: Row(
            children: [
              SongArtwork(song: song),
              const SizedBox(width: AppSizes.sm),
              Expanded(child: _TitleAndArtist(song: song)),
              if (chosen)
                Padding(
                  padding: const EdgeInsets.only(right: AppSizes.xxs),
                  child: Icon(
                    Icons.check_rounded,
                    size: AppSizes.iconSm,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              SongPlayButton(song: song, size: 34),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleAndArtist extends StatelessWidget {
  const _TitleAndArtist({required this.song, this.large = false});
  final Song song;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          song.title,
          maxLines: large ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: (large ? theme.textTheme.titleMedium : theme.textTheme.bodyLarge)
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
        Text(
          song.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// A short centered line in place of the results, with an optional button.
class _Message extends StatelessWidget {
  const _Message(this.text, {this.actionLabel, this.onAction});
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.xl),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: AppSizes.sm),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
