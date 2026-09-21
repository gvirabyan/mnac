import '../entities/milestone.dart';
import '../entities/service_progress.dart';

/// Builds the milestone list for the current progress, flagging any that have
/// newly unlocked relative to the set already celebrated.
///
/// The list is sorted by the date each milestone falls on, so callers can show
/// it as a timeline and take the last unlocked entry as the furthest reached.
class ComputeMilestones {
  const ComputeMilestones();

  List<Milestone> call(
    ServiceProgress progress, {
    Set<String> alreadyUnlocked = const <String>{},
  }) {
    final milestones = <Milestone>[];

    for (final def in MilestoneCatalog.all) {
      if (!_applies(def, progress.totalDays)) continue;
      final unlocked = _isUnlocked(def, progress);
      milestones.add(
        Milestone(
          id: def.id,
          kind: def.kind,
          value: def.value,
          unlocked: unlocked,
          estimatedDate: _dateOf(def, progress),
          justUnlocked: unlocked && !alreadyUnlocked.contains(def.id),
        ),
      );
    }

    // Ordered by calendar day rather than by instant, then by kind. Two
    // milestones that land on the same day are a near-certainty (half of a
    // two-year term is also "one year served"), and comparing timestamps
    // would order those on the minutes that a percentage happens to round to
    // — or on a daylight-saving shift. Dart's sort is not stable either, so
    // the tie is settled explicitly: days served, then days left, then the
    // percentage, which leaves the headline entry last and makes it the one
    // the celebration picks.
    milestones.sort((a, b) {
      final byDay = _dayOf(a.estimatedDate).compareTo(_dayOf(b.estimatedDate));
      return byDay != 0
          ? byDay
          : _tieRank(a.kind).compareTo(_tieRank(b.kind));
    });
    return List.unmodifiable(milestones);
  }

  /// The ids currently unlocked for the given progress.
  Set<String> unlockedIds(ServiceProgress progress) => {
        for (final def in MilestoneCatalog.all)
          if (_applies(def, progress.totalDays) && _isUnlocked(def, progress))
            def.id,
      };

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  static int _tieRank(MilestoneKind kind) => switch (kind) {
        MilestoneKind.daysServed => 0,
        MilestoneKind.daysRemaining => 1,
        MilestoneKind.percent => 2,
      };

  /// Whether a milestone can occur at all within a service of [totalDays].
  ///
  /// A day count equal to the whole term is excluded along with anything
  /// longer: it would land on the discharge date and say the same thing as
  /// 100%.
  static bool _applies(MilestoneDefinition def, int totalDays) =>
      def.kind == MilestoneKind.percent || def.value < totalDays;

  static bool _isUnlocked(MilestoneDefinition def, ServiceProgress progress) =>
      switch (def.kind) {
        MilestoneKind.percent => progress.percent * 100 >= def.value,
        MilestoneKind.daysServed => progress.daysServed >= def.value,
        // Guarded on hasStarted so a profile whose service is still in the
        // future does not count its full term as "few days left".
        MilestoneKind.daysRemaining =>
          progress.hasStarted && progress.daysRemaining <= def.value,
      };

  static DateTime _dateOf(MilestoneDefinition def, ServiceProgress progress) =>
      switch (def.kind) {
        MilestoneKind.percent => progress.start.add(
            Duration(
              seconds: (progress.end.difference(progress.start).inSeconds *
                      def.value /
                      100)
                  .round(),
            ),
          ),
        MilestoneKind.daysServed =>
          progress.start.add(Duration(days: def.value)),
        MilestoneKind.daysRemaining =>
          progress.end.subtract(Duration(days: def.value)),
      };
}
