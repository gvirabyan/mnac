import '../../core/constants/service_constants.dart';
import '../entities/milestone.dart';
import '../entities/service_progress.dart';

/// Builds the milestone list for the current progress, flagging any that have
/// newly unlocked relative to the set already celebrated.
class ComputeMilestones {
  const ComputeMilestones();

  List<Milestone> call(
    ServiceProgress progress, {
    Set<int> alreadyUnlocked = const <int>{},
  }) {
    final totalSeconds = progress.end.difference(progress.start).inSeconds;

    return ServiceConstants.milestoneThresholds.map((threshold) {
      final unlocked = progress.percent * 100 >= threshold;
      final estimatedDate = progress.start.add(
        Duration(seconds: (totalSeconds * threshold / 100).round()),
      );
      return Milestone(
        thresholdPercent: threshold,
        unlocked: unlocked,
        estimatedDate: estimatedDate,
        justUnlocked: unlocked && !alreadyUnlocked.contains(threshold),
      );
    }).toList(growable: false);
  }

  /// The thresholds currently unlocked for the given progress.
  Set<int> unlockedThresholds(ServiceProgress progress) {
    return ServiceConstants.milestoneThresholds
        .where((t) => progress.percent * 100 >= t)
        .toSet();
  }
}
