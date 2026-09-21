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

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: unlocked ? accent : theme.colorScheme.outline,
                  ),
                ),
                if (unit != null)
                  Text(
                    unit,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      height: 1,
                      color: unlocked
                          ? accent.withValues(alpha: 0.8)
                          : theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.milestoneTitle(milestone.id),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSizes.xxs),
                Text(
                  unlocked
                      ? AppDateUtils.formatLong(milestone.estimatedDate)
                      : AppStrings.milestoneLocked,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(
            unlocked ? Icons.verified_rounded : Icons.lock_outline_rounded,
            color: unlocked ? accent : theme.colorScheme.outline,
          ),
        ],
      ),
    );
  }
}
