import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/date_utils.dart';

/// A quiet line with the estimated discharge date: a flag in the accent and
/// the date in the secondary text colour, with no fill, so it reads as
/// information rather than a badge.
class DischargeDateChip extends StatelessWidget {
  const DischargeDateChip({super.key, required this.dischargeDate});

  final DateTime dischargeDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flag_outlined,
            size: AppSizes.iconSm,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSizes.xs),
          Flexible(
            child: Text(
              AppStrings.labeled(
                AppStrings.homeDischargeDate,
                AppDateUtils.formatLong(dischargeDate),
              ),
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}
