import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';

/// How a given day relates to the service timeline.
enum _DayKind { none, withinService, start, today, discharge, milestone }

/// A single-month calendar grid that highlights the start, today, discharge,
/// and milestone days. Monday-first.
class ServiceCalendar extends StatelessWidget {
  const ServiceCalendar({
    super.key,
    required this.month,
    required this.start,
    required this.discharge,
    required this.milestoneDays,
  });

  /// Any date within the month to display.
  final DateTime month;
  final DateTime start;
  final DateTime discharge;

  /// Set of milestone dates, normalized to midnight.
  final Set<DateTime> milestoneDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstOfMonth = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday - 1; // Mon=1 -> 0 blanks
    final today = AppDateUtils.dateOnly(DateTime.now());
    final startDay = AppDateUtils.dateOnly(start);
    final dischargeDay = AppDateUtils.dateOnly(discharge);

    final cells = <Widget>[
      for (final name in AppDateUtils.weekdayShort)
        Center(
          child: Text(name, style: theme.textTheme.labelSmall),
        ),
      for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _DayCell(
          day: day,
          kind: _classify(
            DateTime(month.year, month.month, day),
            today: today,
            startDay: startDay,
            dischargeDay: dischargeDay,
          ),
        ),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSizes.xs,
      crossAxisSpacing: AppSizes.xs,
      children: cells,
    );
  }

  _DayKind _classify(
    DateTime date, {
    required DateTime today,
    required DateTime startDay,
    required DateTime dischargeDay,
  }) {
    if (date == startDay) return _DayKind.start;
    if (date == dischargeDay) return _DayKind.discharge;
    if (date == today) return _DayKind.today;
    if (milestoneDays.contains(date)) return _DayKind.milestone;
    if (!date.isBefore(startDay) && !date.isAfter(dischargeDay)) {
      return _DayKind.withinService;
    }
    return _DayKind.none;
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.kind});
  final int day;
  final _DayKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    Color? fill;
    Color? border;
    Color textColor = theme.colorScheme.onSurface;
    var bold = false;

    switch (kind) {
      case _DayKind.none:
        break;
      case _DayKind.withinService:
        fill = accent.withValues(alpha: 0.08);
      case _DayKind.start:
        fill = AppColors.flagBlue;
        textColor = Colors.white;
        bold = true;
      case _DayKind.discharge:
        fill = AppColors.success;
        textColor = Colors.white;
        bold = true;
      case _DayKind.today:
        border = accent;
        textColor = accent;
        bold = true;
      case _DayKind.milestone:
        fill = AppColors.flagRed.withValues(alpha: 0.16);
        border = AppColors.flagRed;
        textColor = AppColors.flagRed;
        bold = true;
    }

    return Container(
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: border == null ? null : Border.all(color: border, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '$day',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: textColor,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}
