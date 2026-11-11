/// What a milestone counts.
enum MilestoneKind {
  /// Percent of the whole service completed.
  percent,

  /// Whole days served since the start.
  daysServed,

  /// Whole days left until discharge.
  daysRemaining,

  /// One the user added: their own title on a date they picked.
  custom,
}

/// An achievement the user added themselves, e.g. "Leave" on a given day.
/// Kept on the soldier it belongs to.
class CustomMilestone {
  const CustomMilestone({
    required this.id,
    required this.title,
    required this.date,
  });

  /// Stable across edits; the milestone built from it is [milestoneId].
  final String id;
  final String title;

  /// The day it opens; only the date part counts.
  final DateTime date;

  /// The id of the [Milestone] made from this, as persisted once
  /// celebrated. Prefixed so it can never clash with a catalogue id.
  String get milestoneId => '$customIdPrefix$id';

  static const String customIdPrefix = 'custom:';

  CustomMilestone copyWith({String? title, DateTime? date}) => CustomMilestone(
        id: id,
        title: title ?? this.title,
        date: date ?? this.date,
      );

  @override
  bool operator ==(Object other) =>
      other is CustomMilestone &&
      other.id == id &&
      other.title == title &&
      other.date == date;

  @override
  int get hashCode => Object.hash(id, title, date);
}

/// One entry in the milestone catalogue: what it counts and at which value it
/// unlocks. Display strings live in the presentation layer (Armenian), keyed
/// by [id]; the domain only models the rule.
class MilestoneDefinition {
  const MilestoneDefinition(this.id, this.kind, this.value);

  /// Stable identifier, also what gets persisted once celebrated. Never
  /// reuse an id for a different rule: an old id in a user's unlocked set
  /// would silently suppress the celebration of the new one.
  final String id;

  final MilestoneKind kind;

  /// Percent for [MilestoneKind.percent], otherwise a number of days.
  final int value;
}

/// Every milestone the app can award, in no particular order — the compute
/// step sorts them by the date each falls on, which depends on the profile.
///
/// Day-based entries are skipped for a service shorter than they are (a
/// one-year term never reaches "500 days", and "one year" there would land on
/// the discharge date itself, duplicating 100%).
abstract final class MilestoneCatalog {
  MilestoneCatalog._();

  static const List<MilestoneDefinition> all = [
    // Days served.
    MilestoneDefinition('day30', MilestoneKind.daysServed, 30),
    MilestoneDefinition('day100', MilestoneKind.daysServed, 100),
    MilestoneDefinition('day180', MilestoneKind.daysServed, 180),
    MilestoneDefinition('day300', MilestoneKind.daysServed, 300),
    MilestoneDefinition('day365', MilestoneKind.daysServed, 365),
    MilestoneDefinition('day500', MilestoneKind.daysServed, 500),
    // Days left.
    MilestoneDefinition('left300', MilestoneKind.daysRemaining, 300),
    MilestoneDefinition('left200', MilestoneKind.daysRemaining, 200),
    MilestoneDefinition('left100', MilestoneKind.daysRemaining, 100),
    MilestoneDefinition('left50', MilestoneKind.daysRemaining, 50),
    MilestoneDefinition('left7', MilestoneKind.daysRemaining, 7),
    MilestoneDefinition('left1', MilestoneKind.daysRemaining, 1),
    // Percent of the way.
    MilestoneDefinition('pct25', MilestoneKind.percent, 25),
    MilestoneDefinition('pct50', MilestoneKind.percent, 50),
    MilestoneDefinition('pct75', MilestoneKind.percent, 75),
    MilestoneDefinition('pct90', MilestoneKind.percent, 90),
    MilestoneDefinition('pct99', MilestoneKind.percent, 99),
    MilestoneDefinition('pct100', MilestoneKind.percent, 100),
  ];
}

/// A milestone resolved against a profile: when it falls and whether it has
/// been reached.
class Milestone {
  const Milestone({
    required this.id,
    required this.kind,
    required this.value,
    required this.unlocked,
    required this.estimatedDate,
    required this.justUnlocked,
    this.title,
  });

  /// The catalogue id, e.g. `pct50`, `day100`, `left30`, or
  /// [CustomMilestone.milestoneId] for one the user added.
  final String id;

  /// The user's own title for a [MilestoneKind.custom] one; null for the
  /// catalogue, whose titles come from the translations by [id].
  final String? title;

  final MilestoneKind kind;

  /// Percent for [MilestoneKind.percent], a number of days for the day-based
  /// kinds, 0 for [MilestoneKind.custom].
  final int value;

  /// Whether the current progress has reached this milestone.
  final bool unlocked;

  /// The calendar date this milestone is/was reached. Exact for the day-based
  /// kinds, estimated (from the total duration) for percentages.
  final DateTime estimatedDate;

  /// True when this milestone has been reached but not yet celebrated.
  final bool justUnlocked;
}
