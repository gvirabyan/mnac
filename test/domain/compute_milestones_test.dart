import 'package:depitun/domain/entities/milestone.dart';
import 'package:depitun/domain/entities/soldier_profile.dart';
import 'package:depitun/domain/usecases/compute_milestones.dart';
import 'package:depitun/domain/usecases/compute_service_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const computeProgress = ComputeServiceProgress();
  const computeMilestones = ComputeMilestones();

  SoldierProfile profile(DateTime start, {int days = 730}) => SoldierProfile(
        id: 'test',
        serviceStart: start,
        serviceDurationDays: days,
        createdAt: start,
      );

  test('at 50% the percent and day milestones reached so far are unlocked',
      () {
    final now = DateTime(2026, 6, 27);
    final start = now.subtract(const Duration(days: 365));
    final progress = computeProgress(profile(start), now);

    final unlocked = computeMilestones(progress)
        .where((m) => m.unlocked)
        .map((m) => m.id)
        .toSet();

    expect(unlocked, containsAll(['pct25', 'pct50', 'day100', 'day365']));
    expect(unlocked, isNot(contains('pct75')));
    // 365 days left of 730 — none of the countdown milestones yet.
    expect(unlocked, isNot(contains('left300')));
  });

  test('countdown milestones unlock on days remaining', () {
    final now = DateTime(2026, 6, 27);
    final start = now.subtract(const Duration(days: 700)); // 30 days left
    final progress = computeProgress(profile(start), now);

    final unlocked = computeMilestones(progress)
        .where((m) => m.unlocked)
        .map((m) => m.id)
        .toSet();

    expect(unlocked, containsAll(['left300', 'left200', 'left100', 'left50']));
    expect(unlocked, isNot(contains('left7')));
    expect(unlocked, isNot(contains('pct99')));
  });

  test('day milestones longer than the term are not offered', () {
    final now = DateTime(2026, 6, 27);
    final start = now.subtract(const Duration(days: 10));
    final progress = computeProgress(profile(start, days: 365), now);

    final ids = computeMilestones(progress).map((m) => m.id).toSet();

    // A one-year term ends exactly on day 365, so that milestone would only
    // repeat 100%; 500 days never arrives at all.
    expect(ids, isNot(contains('day365')));
    expect(ids, isNot(contains('day500')));
    expect(ids, contains('day300'));
    expect(ids, contains('left300'));
  });

  test('the list is ordered by the date each milestone falls on', () {
    final now = DateTime(2026, 6, 27);
    final start = now.subtract(const Duration(days: 365));
    final milestones = computeMilestones(computeProgress(profile(start), now));

    for (var i = 1; i < milestones.length; i++) {
      expect(
        milestones[i].estimatedDate
            .isBefore(milestones[i - 1].estimatedDate),
        isFalse,
      );
    }
    expect(milestones.last.id, 'pct100');
  });

  test('justUnlocked excludes already-celebrated milestones', () {
    final now = DateTime(2026, 6, 27);
    final start = now.subtract(const Duration(days: 365));
    final progress = computeProgress(profile(start), now);

    final celebrated =
        computeMilestones(progress).where((m) => m.unlocked).map((m) => m.id);
    final justUnlocked = computeMilestones(
      progress,
      alreadyUnlocked: {...celebrated}..remove('pct50'),
    ).where((m) => m.justUnlocked).map((m) => m.id);

    expect(justUnlocked, ['pct50']);
  });

  test('unlockedIds matches the unlocked milestones of the list', () {
    final now = DateTime(2026, 6, 27);
    final start = now.subtract(const Duration(days: 700));
    final progress = computeProgress(profile(start), now);

    expect(
      computeMilestones.unlockedIds(progress),
      computeMilestones(progress)
          .where((m) => m.unlocked)
          .map((m) => m.id)
          .toSet(),
    );
  });

  test('a profile whose service has not started unlocks nothing', () {
    final now = DateTime(2026, 6, 27);
    final start = now.add(const Duration(days: 10));
    final progress = computeProgress(profile(start), now);

    expect(computeMilestones.unlockedIds(progress), isEmpty);
    expect(MilestoneCatalog.all.length, 18);
  });
}
