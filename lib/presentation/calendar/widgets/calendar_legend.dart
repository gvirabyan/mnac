import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';

/// Explains the meaning of the highlighted days in the calendar.
class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: AppSizes.lg,
      runSpacing: AppSizes.sm,
      children: [
        _LegendItem(color: AppColors.flagBlue, label: AppStrings.calendarStart),
        _LegendItem(color: accent, label: AppStrings.calendarToday),
        _LegendItem(color: AppColors.success, label: AppStrings.calendarDischarge),
        _LegendItem(color: AppColors.flagRed, label: AppStrings.calendarMilestone),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSizes.xs),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
