import '../../core/utils/duration_breakdown.dart';

/// A computed snapshot of service progress at a given instant.
///
/// Produced by the compute-progress use case; never persisted.
class ServiceProgress {
  const ServiceProgress({
    required this.start,
    required this.end,
    required this.now,
    required this.totalDays,
    required this.daysServed,
    required this.daysRemaining,
    required this.percent,
    required this.remaining,
    required this.elapsed,
    required this.weeksServed,
    required this.monthsServed,
  });

  final DateTime start;
  final DateTime end;
  final DateTime now;

  final int totalDays;
  final int daysServed;
  final int daysRemaining;

  /// Completion fraction in the range 0..1.
  final double percent;

  /// Hierarchical remaining-time breakdown for the countdown UI.
  final DurationBreakdown remaining;

  /// Hierarchical elapsed-time breakdown (time already served).
  final DurationBreakdown elapsed;

  final int weeksServed;
  final int monthsServed;

  /// Whether service has begun (now is at/after start).
  bool get hasStarted => !now.isBefore(start);

  /// Whether service is fully complete.
  bool get isComplete => !now.isBefore(end);

  /// Percent as an integer 0..100.
  int get percentInt => (percent * 100).clamp(0, 100).round();
}
