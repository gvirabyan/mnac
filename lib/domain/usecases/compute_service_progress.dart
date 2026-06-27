import '../../core/utils/duration_breakdown.dart';
import '../entities/service_progress.dart';
import '../entities/soldier_profile.dart';

/// Computes a [ServiceProgress] snapshot for a profile at a given instant.
class ComputeServiceProgress {
  const ComputeServiceProgress();

  ServiceProgress call(SoldierProfile profile, DateTime now) {
    final start = profile.serviceStart;
    final end = profile.dischargeDate;

    final totalSeconds = end.difference(start).inSeconds;
    final elapsedSeconds =
        now.difference(start).inSeconds.clamp(0, totalSeconds);

    final percent = totalSeconds <= 0
        ? 1.0
        : (elapsedSeconds / totalSeconds).clamp(0.0, 1.0);

    final totalDays = profile.serviceDurationDays;
    final cappedNow = now.isAfter(end)
        ? end
        : (now.isBefore(start) ? start : now);

    final daysServed =
        cappedNow.difference(start).inDays.clamp(0, totalDays);
    final daysRemaining = (totalDays - daysServed).clamp(0, totalDays);

    return ServiceProgress(
      start: start,
      end: end,
      now: now,
      totalDays: totalDays,
      daysServed: daysServed,
      daysRemaining: daysRemaining,
      percent: percent,
      remaining: DurationBreakdown.between(now, end),
      elapsed: DurationBreakdown.between(start, cappedNow),
      weeksServed: daysServed ~/ 7,
      monthsServed: _wholeMonthsBetween(start, cappedNow),
    );
  }

  /// Counts whole calendar months between [from] and [to] (to >= from).
  static int _wholeMonthsBetween(DateTime from, DateTime to) {
    if (!to.isAfter(from)) return 0;
    var months = (to.year - from.year) * 12 + (to.month - from.month);
    // Subtract one if the day-of-month hasn't been reached yet.
    if (to.day < from.day) months--;
    return months < 0 ? 0 : months;
  }
}
