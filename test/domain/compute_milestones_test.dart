import 'package:depitun/domain/entities/soldier_profile.dart';
import 'package:depitun/domain/usecases/compute_milestones.dart';
import 'package:depitun/domain/usecases/compute_service_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const computeProgress = ComputeServiceProgress();
  const computeMilestones = ComputeMilestones();

  SoldierProfile profile(DateTime start) => SoldierProfile(
        id: 'test',
        serviceStart: start,
        serviceDurationDays: 730,
        createdAt: start,
      );

  test('at 50% only 25 and 50 thresholds are unlocked', () {
    final now = DateTime(2026, 6, 27);
    final start = now.subtract(const Duration(days: 365));
    final progress = computeProgress(profile(start), now);

    final milestones = computeMilestones(progress);
    final unlocked =
        milestones.where((m) => m.unlocked).map((m) => m.thresholdPercent);

    expect(unlocked, containsAll([25, 50]));
    expect(unlocked, isNot(contains(75)));
  });

  test('justUnlocked excludes already-celebrated thresholds', () {
    final now = DateTime(2026, 6, 27);
    final start = now.subtract(const Duration(days: 365));
    final progress = computeProgress(profile(start), now);

    final milestones =
        computeMilestones(progress, alreadyUnlocked: {25});
    final justUnlocked = milestones
        .where((m) => m.justUnlocked)
        .map((m) => m.thresholdPercent)
        .toSet();

    expect(justUnlocked, {50});
  });

  test('unlockedThresholds matches unlocked milestones', () {
    final now = DateTime(2026, 6, 27);
    final start = now.subtract(const Duration(days: 700)); // ~96%
    final progress = computeProgress(profile(start), now);

    final set = computeMilestones.unlockedThresholds(progress);
    expect(set, containsAll([25, 50, 75, 90, 95]));
    expect(set, isNot(contains(99)));
  });
}
