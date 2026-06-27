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
    final percent = milestone.thresholdPercent;

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
            child: Text(
              '$percent%',
              style: theme.textTheme.titleMedium?.copyWith(
                color: unlocked ? accent : theme.colorScheme.outline,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.milestoneTitle(percent),
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
