import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/l10n/app_strings.dart';

/// A horizontal stacked bar visualizing served vs. remaining days, with a
/// legend beneath. The served portion animates to [percent].
class ServedRemainingBar extends StatelessWidget {
  const ServedRemainingBar({
    super.key,
    required this.percent,
    required this.daysServed,
    required this.daysRemaining,
    this.animate = true,
  });

  final double percent;
  final int daysServed;
  final int daysRemaining;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final track = theme.colorScheme.surfaceContainerHighest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percent.clamp(0.0, 1.0)),
            duration: animate ? const Duration(milliseconds: 900) : Duration.zero,
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return Stack(
                  children: [
                    Container(height: 18, width: width, color: track),
                    Container(height: 18, width: width * value, color: accent),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        Wrap(
          spacing: AppSizes.lg,
          runSpacing: AppSizes.xs,
          children: [
            _LegendDot(color: accent, label: AppStrings.statsDaysServed, count: daysServed),
            _LegendDot(color: track, label: AppStrings.statsDaysRemaining, count: daysRemaining),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.count,
  });

  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSizes.xs),
        Text('$label ($count)', style: theme.textTheme.bodySmall),
      ],
    );
  }
}
