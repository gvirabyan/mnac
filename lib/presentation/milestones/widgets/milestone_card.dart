import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/milestone.dart';
import '../../shared/widgets/glass_card.dart';

/// A single milestone card; styled differently for locked vs. unlocked state.
class MilestoneCard extends StatelessWidget {
  const MilestoneCard({super.key, required this.milestone});

  final Milestone milestone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final unlocked = milestone.unlocked;
    // Percentages read as "50%"; the day-based kinds show the count with a
    // unit underneath, so "100 days served" and "100 days left" cannot be
    // mistaken for one another at a glance.
    final (badge, unit) = switch (milestone.kind) {
      MilestoneKind.percent => ('${milestone.value}%', null),
      MilestoneKind.daysServed =>
        ('${milestone.value}', AppStrings.milestoneUnitDays),
      MilestoneKind.daysRemaining =>
        ('${milestone.value}', AppStrings.milestoneUnitLeft),
    };

    // Bottom line: the day it opened, or the day it opens and how far off.
    final date = AppDateUtils.formatLong(milestone.estimatedDate);
    final daysLeft =
        AppDateUtils.daysBetween(DateTime.now(), milestone.estimatedDate);
    final dateLine = unlocked
        ? AppStrings.milestoneOpenedOn(date)
        : '${AppStrings.milestoneOpensOn(date)} · '
            '${AppStrings.milestoneInDays(daysLeft)}';

    // Tighter than a default GlassCard so the extra date line still leaves
    // the card about as tall as it was without it.
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unlocked
                      ? accent.withValues(alpha: 0.16)
                      : theme.colorScheme.surfaceContainerHighest,
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      badge,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: unlocked ? accent : theme.colorScheme.outline,
                      ),
                    ),
                    if (unit != null)
                      Text(
                        unit,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 8,
                          height: 1,
                          color: unlocked
                              ? accent.withValues(alpha: 0.8)
                              : theme.colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  AppStrings.milestoneTitle(milestone.id),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Icon(
                unlocked ? Icons.verified_rounded : Icons.lock_outline_rounded,
                size: 20,
                color: unlocked ? accent : theme.colorScheme.outline,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          const SizedBox(height: AppSizes.xs),
          Row(
            children: [
              Icon(
                unlocked ? Icons.event_available_rounded : Icons.event_rounded,
                size: 14,
                color: unlocked ? accent : theme.colorScheme.outline,
              ),
              const SizedBox(width: AppSizes.xxs),
              // One line, whatever the screen width: shrinks rather than
              // wraps, so the card keeps its height.
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    dateLine,
                    maxLines: 1,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: unlocked ? accent : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
