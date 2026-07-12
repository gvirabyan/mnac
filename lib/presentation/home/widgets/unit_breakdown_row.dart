import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/duration_breakdown.dart';
import '../../shared/widgets/animated_counter.dart';

/// A single value+label unit cell in a breakdown page.
class UnitValue {
  const UnitValue(this.value, this.label, {this.pad = false});

  final int value;
  final String label;

  /// When true the number is zero-padded to two digits (used for H/Min/Sec).
  final bool pad;
}

/// Displays time units as animated numbers above their Armenian labels,
/// laid out in one or more rows.
class UnitBreakdownRow extends StatelessWidget {
  const UnitBreakdownRow({
    super.key,
    required this.rows,
    this.animate = true,
  });

  /// Builds the classic hierarchical layout: Y / M / W / D over H / Min / Sec.
  static List<List<UnitValue>> hierarchicalRows(DurationBreakdown b) => [
        [
          UnitValue(b.years, AppStrings.years),
          UnitValue(b.months, AppStrings.months),
          UnitValue(b.weeks, AppStrings.weeks),
          UnitValue(b.days, AppStrings.days),
        ],
        [
          UnitValue(b.hours, AppStrings.hours, pad: true),
          UnitValue(b.minutes, AppStrings.minutes, pad: true),
          UnitValue(b.seconds, AppStrings.seconds, pad: true),
        ],
      ];

  final List<List<UnitValue>> rows;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSizes.md),
          Row(
            children: [
              for (final unit in rows[i])
                _Cell(
                  value: unit.value,
                  label: unit.label,
                  animate: animate,
                  pad: unit.pad,
                ),
            ],
          ),
        ],
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
