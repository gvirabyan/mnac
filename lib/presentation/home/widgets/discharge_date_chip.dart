import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/date_utils.dart';

/// A pill showing the estimated discharge date.
class DischargeDateChip extends StatelessWidget {
  const DischargeDateChip({super.key, required this.dischargeDate});

  final DateTime dischargeDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flag_rounded,
            size: AppSizes.iconSm,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSizes.xs),
          Text(
            '${AppStrings.homeDischargeDate}՝ ${AppDateUtils.formatLong(dischargeDate)}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
