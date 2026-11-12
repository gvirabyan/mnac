import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/date_utils.dart';

/// A slim bar of the service so far, with the start date under its left end
/// and the discharge date under its right end. The filled part animates to
/// [percent].
class ServedRemainingBar extends StatelessWidget {
  const ServedRemainingBar({
    super.key,
    required this.percent,
    required this.start,
    required this.end,
    this.animate = true,
  });

  final double percent;
  final DateTime start;
  final DateTime end;
  final bool animate;

  static const double _height = 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final track = theme.colorScheme.onSurface.withValues(alpha: 0.08);
    final dateStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percent.clamp(0.0, 1.0)),
            duration:
                animate ? const Duration(milliseconds: 900) : Duration.zero,
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Stack(
              children: [
                Container(height: _height, color: track),
                FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    height: _height,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusPill),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Row(
          children: [
            Text(AppDateUtils.formatNumeric(start), style: dateStyle),
            const Spacer(),
            Text(AppDateUtils.formatNumeric(end), style: dateStyle),
          ],
        ),
      ],
    );
  }
}
