import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/app_router.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/service_constants.dart';
import '../../core/di/providers.dart';
import '../../core/l10n/app_strings.dart';
import '../milestones/milestones_screen.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/service_progress.dart';
import '../home/home_controller.dart';
import '../shared/state/settings_controller.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/glass_card.dart';
import '../shared/widgets/gradient_scaffold.dart';
import '../shared/widgets/section_header.dart';
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
      appBar: AppBar(title: const Text(AppStrings.statsTitle)),
      body: progress == null
          ? const EmptyState(
              icon: Icons.insights_outlined,
              title: AppStrings.homeNoSoldierTitle,
              subtitle: AppStrings.homeNoSoldierSubtitle,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.md,
                AppSizes.screenPadding,
                AppSizes.xxl,
              ),
              children: [
                _StatGrid(progress: progress),
                const SizedBox(height: AppSizes.xl),
                const SectionHeader(title: AppStrings.statsProgress),
                const SizedBox(height: AppSizes.md),
                _ProgressCard(progress: progress, animate: animate),
                const SizedBox(height: AppSizes.xl),
                const SectionHeader(title: AppStrings.statsMilestonesPeek),
                const SizedBox(height: AppSizes.md),
                _MilestonePeek(progress: progress, ref: ref),
              ],
            ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.progress});
  final ServiceProgress progress;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      StatTile(
        icon: Icons.military_tech_outlined,
        value: '${progress.daysServed}',
        label: AppStrings.statsDaysServed,
      ),
      StatTile(
        icon: Icons.hourglass_bottom_rounded,
        value: '${progress.daysRemaining}',
        label: AppStrings.statsDaysRemaining,
      ),
      StatTile(
        icon: Icons.date_range_rounded,
        value: '${progress.weeksServed}',
        label: AppStrings.statsWeeksServed,
      ),
      StatTile(
        icon: Icons.calendar_month_rounded,
        value: '${progress.monthsServed}',
        label: AppStrings.statsMonthsServed,
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: tiles[0]),
            const SizedBox(width: AppSizes.md),
            Expanded(child: tiles[1]),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          children: [
            Expanded(child: tiles[2]),
            const SizedBox(width: AppSizes.md),
            Expanded(child: tiles[3]),
          ],
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress, required this.animate});
  final ServiceProgress progress;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${progress.percentInt}%',
            style: theme.textTheme.displaySmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: AppSizes.md),
          ServedRemainingBar(
            percent: progress.percent,
            daysServed: progress.daysServed,
            daysRemaining: progress.daysRemaining,
            animate: animate,
          ),
        ],
      ),
    );
  }
}

class _MilestonePeek extends StatelessWidget {
  const _MilestonePeek({required this.progress, required this.ref});
  final ServiceProgress progress;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = ref
        .read(computeMilestonesProvider)
        .unlockedThresholds(progress)
        .length;
    final total = ServiceConstants.milestoneThresholds.length;

    return GlassCard(
      onTap: () => Navigator.of(context).push(
        appPageRoute(const MilestonesScreen()),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_outlined,
              color: theme.colorScheme.primary, size: AppSizes.iconLg),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.milestonesTitle,
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSizes.xxs),
                Text('$unlocked / $total',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: theme.colorScheme.outline),
        ],
      ),
    );
  }
}
