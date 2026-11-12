import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/app_router.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/di/providers.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/utils/date_utils.dart';
import '../milestones/milestone_text.dart';
import '../milestones/milestones_screen.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/service_progress.dart';
import '../home/home_controller.dart';
import '../shared/state/settings_controller.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/gradient_scaffold.dart';
import '../shared/widgets/quiet_card.dart';
import 'widgets/served_remaining_bar.dart';
import 'widgets/stat_tile.dart';

/// Statistics tab: served/remaining counts, progress visualization, and a
/// milestone summary.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Statistics change at most once per day; gate rebuilds on daysServed so the
    // (always-alive) tab doesn't rebuild every second with the clock tick.
    ref.watch(serviceProgressProvider.select((p) => p?.daysServed));
    final progress = ref.read(serviceProgressProvider);
    final animate = ref.watch(
          settingsControllerProvider.select((s) => s.animationLevel),
        ) !=
        AnimationLevel.none;

    return GradientScaffold(
      appBar: AppBar(title: Text(AppStrings.statsTitle)),
      body: progress == null
          ? EmptyState(
              icon: Icons.insights_outlined,
              title: AppStrings.homeNoSoldierTitle,
              subtitle: AppStrings.homeNoSoldierSubtitle,
            )
          : ListView(
              // Extra bottom inset so the last card scrolls clear of the
              // floating glass nav bar (the shell uses extendBody: true).
              padding: EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.md,
                AppSizes.screenPadding,
                AppSizes.xxl + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                _ProgressCard(progress: progress, animate: animate),
                const SizedBox(height: AppSizes.lg),
                _StatGrid(progress: progress),
                const SizedBox(height: AppSizes.lg),
                _MilestonePeek(progress: progress, ref: ref),
              ],
            ),
    );
  }
}

/// The four counts as a short list, a label on the left and the number on
/// the right, parted by hairlines.
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.progress});
  final ServiceProgress progress;

  @override
  Widget build(BuildContext context) {
    final hairline =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06);
    final rows = [
      StatTile(
        value: '${progress.daysServed}',
        label: AppStrings.statsDaysServed,
      ),
      StatTile(
        value: '${progress.daysRemaining}',
        label: AppStrings.statsDaysRemaining,
      ),
      StatTile(
        value: '${progress.weeksServed}',
        label: AppStrings.statsWeeksServed,
      ),
      StatTile(
        value: '${progress.monthsServed}',
        label: AppStrings.statsMonthsServed,
      ),
    ];

    return QuietCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.xs,
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: hairline),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// The percentage, the one gold figure on the screen, over a slim bar that
/// runs from the start date to the discharge date.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress, required this.animate});
  final ServiceProgress progress;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return QuietCard(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.statsProgress,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSizes.xxs),
          Text(
            '${progress.percentInt}%',
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSizes.md),
          ServedRemainingBar(
            percent: progress.percent,
            start: progress.start,
            end: progress.end,
            animate: animate,
          ),
        ],
      ),
    );
  }
}

/// Achievements: a caption with the count, a thin bar of how many are open,
/// and the next one ahead with when it comes.
class _MilestonePeek extends StatelessWidget {
  const _MilestonePeek({required this.progress, required this.ref});
  final ServiceProgress progress;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final accent = theme.colorScheme.primary;
    // Counted off the resolved list rather than the catalogue: the day-based
    // milestones that fall past the discharge date are not offered at all for
    // a shorter term, and must not be counted as forever-locked.
    final milestones = ref.read(computeMilestonesProvider)(progress);
    final unlocked = milestones.where((m) => m.unlocked).length;
    final total = milestones.length;

    final ahead = milestones.where((m) => !m.unlocked).toList()
      ..sort((a, b) => a.estimatedDate.compareTo(b.estimatedDate));
    final next = ahead.isEmpty ? null : ahead.first;

    final caption = theme.textTheme.bodySmall?.copyWith(
      color: muted,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return QuietCard(
      padding: const EdgeInsets.all(AppSizes.lg),
      onTap: () => Navigator.of(context).push(
        appPageRoute(const MilestonesScreen()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_outlined,
                  size: AppSizes.iconSm, color: accent),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                child: Text(AppStrings.milestonesTitle, style: caption),
              ),
              Text('$unlocked / $total', style: caption),
              const SizedBox(width: AppSizes.xxs),
              Icon(Icons.chevron_right_rounded,
                  size: AppSizes.iconSm, color: muted),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          // How many are open, in the accent like the service bar above.
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : unlocked / total,
              minHeight: 4,
              backgroundColor: accent.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: AppSizes.md),
            Text(AppStrings.statsNextMilestone, style: caption),
            const SizedBox(height: AppSizes.xxs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    next.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Text(
                  AppStrings.milestoneInDays(
                    AppDateUtils.daysBetween(progress.now, next.estimatedDate),
                  ),
                  style: caption?.copyWith(color: accent),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
