import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/duration_breakdown.dart';
import '../../shared/widgets/animated_counter.dart';

/// Displays the remaining time broken into Y / M / W / D and H / Min / Sec,
/// each as an animated number above its Armenian label.
class UnitBreakdownRow extends StatelessWidget {
  const UnitBreakdownRow({
    super.key,
    required this.breakdown,
    this.animate = true,
  });

  final DurationBreakdown breakdown;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _Cell(value: breakdown.years, label: AppStrings.years, animate: animate),
            _Cell(value: breakdown.months, label: AppStrings.months, animate: animate),
            _Cell(value: breakdown.weeks, label: AppStrings.weeks, animate: animate),
            _Cell(value: breakdown.days, label: AppStrings.days, animate: animate),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          children: [
            _Cell(value: breakdown.hours, label: AppStrings.hours, animate: animate, pad: true),
            _Cell(value: breakdown.minutes, label: AppStrings.minutes, animate: animate, pad: true),
            _Cell(value: breakdown.seconds, label: AppStrings.seconds, animate: animate, pad: true),
          ],
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.value,
    required this.label,
    required this.animate,
    this.pad = false,
  });

  final int value;
  final String label;
  final bool animate;
  final bool pad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          AnimatedCounter(
            value: value,
            animate: animate,
            minDigits: pad ? 2 : 1,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSizes.xxs),
          Text(
            label,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
