import 'dart:math' as math;

/// A calendar-aware hierarchical breakdown of the time between two instants.
///
/// Each field holds the remainder after the larger fields are accounted for,
/// e.g. `2 years, 3 months, 1 week, 4 days, 5 hours, 6 minutes, 7 seconds`.
class DurationBreakdown {
  const DurationBreakdown({
    required this.years,
    required this.months,
    required this.weeks,
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
  });

  final int years;
  final int months;
  final int weeks;
  final int days;
  final int hours;
  final int minutes;
  final int seconds;

  static const DurationBreakdown zero = DurationBreakdown(
    years: 0,
    months: 0,
    weeks: 0,
    days: 0,
    hours: 0,
    minutes: 0,
    seconds: 0,
  );

  /// Computes the breakdown from [from] up to [to].
  ///
  /// Returns [zero] when [to] is not after [from].
  factory DurationBreakdown.between(DateTime from, DateTime to) {
    if (!to.isAfter(from)) return zero;

    var years = 0;
    while (!_addMonths(from, (years + 1) * 12).isAfter(to)) {
      years++;
    }
    var anchor = _addMonths(from, years * 12);

    var months = 0;
    while (!_addMonths(anchor, months + 1).isAfter(to)) {
      months++;
    }
    anchor = _addMonths(anchor, months);

    final remainder = to.difference(anchor);
    final totalDays = remainder.inDays;

    return DurationBreakdown(
      years: years,
      months: months,
      weeks: totalDays ~/ 7,
      days: totalDays % 7,
      hours: remainder.inHours % 24,
      minutes: remainder.inMinutes % 60,
      seconds: remainder.inSeconds % 60,
    );
  }

  /// Adds [months] calendar months to [date], clamping the day to the target
  /// month's length and preserving the time of day.
  static DateTime _addMonths(DateTime date, int months) {
    final totalMonths = date.month - 1 + months;
    final year = date.year + (totalMonths ~/ 12);
    final month = (totalMonths % 12) + 1;
    final day = math.min(date.day, _daysInMonth(year, month));
    return DateTime(
      year,
      month,
      day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
    );
  }

  static int _daysInMonth(int year, int month) {
    final firstOfNext = (month == 12)
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    return firstOfNext.subtract(const Duration(days: 1)).day;
  }
}
