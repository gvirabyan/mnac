/// A progress milestone (e.g. 25%, 50%) that unlocks as service advances.
///
/// Display title/message live in the presentation layer (Armenian strings);
/// the domain only models thresholds, unlock state, and estimated dates.
class Milestone {
  const Milestone({
    required this.thresholdPercent,
    required this.unlocked,
    required this.estimatedDate,
    required this.justUnlocked,
  });

  /// One of the configured thresholds (25, 50, 75, 90, 95, 99, 100).
  final int thresholdPercent;

  /// Whether the current progress has reached this threshold.
  final bool unlocked;

  /// The estimated calendar date this milestone is/was reached.
  final DateTime estimatedDate;

  /// True when this milestone became unlocked but hasn't been celebrated yet.
  final bool justUnlocked;
}
