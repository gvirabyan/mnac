import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/l10n/app_strings.dart';
import '../../domain/entities/milestone.dart';
import '../shared/state/soldiers_controller.dart';
import '../shared/widgets/app_loading.dart';
import '../shared/widgets/gradient_scaffold.dart';
import 'custom_milestone_editor.dart';
import 'milestones_controller.dart';
import 'widgets/milestone_card.dart';

/// Milestones screen: the list of progress milestones with locked/unlocked
/// styling, plus the user's own, which they add here and edit by tapping.
/// Reachable from Home and Statistics.
class MilestonesScreen extends ConsumerWidget {
  const MilestonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestones = ref.watch(milestonesProvider);
    final soldier = ref.watch(activeSoldierProvider);

    return GradientScaffold(
      appBar: AppBar(title: Text(AppStrings.milestonesTitle)),
      body: milestones.isEmpty
          ? const AppLoading()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.md,
                AppSizes.screenPadding,
                AppSizes.xxl,
              ),
              // The add card heads the list, so it is the first thing seen
              // and never sits over a card the way a floating button would.
              itemCount: milestones.length + 1,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSizes.md),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _AddCustomCard(
                    onTap: soldier == null
                        ? null
                        : () => showCustomMilestoneEditor(context, ref),
                  );
                }
                final milestone = milestones[index - 1];
                final custom = milestone.kind == MilestoneKind.custom
                    ? soldier?.customMilestones
                        .where((c) => c.milestoneId == milestone.id)
                        .firstOrNull
                    : null;
                return MilestoneCard(
                  milestone: milestone,
                  onTap: custom == null
                      ? null
                      : () => showCustomMilestoneEditor(
                            context,
                            ref,
                            existing: custom,
                          ),
                );
              },
            ),
    );
  }
}

/// Invites the user to add an achievement of their own: an accent-outlined
/// card, set apart from the milestones below it by its border and plus.
class _AddCustomCard extends StatelessWidget {
  const _AddCustomCard({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final radius = BorderRadius.circular(AppSizes.radiusLg);

    return Material(
      color: accent.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: accent.withValues(alpha: 0.45), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.customMilestoneAdd,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.customMilestoneAddHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}
