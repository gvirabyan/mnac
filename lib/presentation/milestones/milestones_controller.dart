import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/milestone.dart';
import '../home/home_controller.dart';
import '../shared/state/settings_controller.dart';
import '../shared/state/soldiers_controller.dart';

/// The full milestone list for the milestones screen (recomputed each tick).
final milestonesProvider = Provider.autoDispose<List<Milestone>>((ref) {
  final progress = ref.watch(serviceProgressProvider);
  if (progress == null) return const [];
  final soldierId = ref.watch(activeSoldierProvider.select((s) => s?.id));
  final unlocked = ref.watch(
    settingsControllerProvider.select((s) => s.milestonesOf(soldierId)),
  );
  return ref.watch(computeMilestonesProvider)(
    progress,
    alreadyUnlocked: unlocked,
  );
});

/// Records which milestones have already been put on screen today, as
/// `day|soldierId|milestoneId` entries.
///
/// The dialog is shown once a day, not once an app open: the achievement is
/// worth surfacing when the user comes back to the app having crossed it, but
/// not again every time they switch away and return. Each soldier is tracked
/// separately — two profiles can reach something on the same day, and a
/// dialog shown for one must not silence the other.
const String milestoneRecapShownKey = 'milestone_recap_shown';

/// The milestone whose date falls on today, if it has been reached — what the
/// app opens with on the day something was achieved.
///
/// Read imperatively (and never listened to), so being autoDispose means every
/// read recomputes against the current clock rather than serving yesterday's
/// answer.
final todaysMilestoneProvider = Provider.autoDispose<Milestone?>((ref) {
  final progress = ref.read(serviceProgressProvider);
  if (progress == null) return null;

  final soldierId = ref.read(activeSoldierProvider)?.id;
  final unlocked = ref.read(
    settingsControllerProvider.select((s) => s.milestonesOf(soldierId)),
  );
  final today = progress.now;

  // Date-ordered, so the last match is the furthest milestone of the day when
  // several land together.
  final todays = ref
      .read(computeMilestonesProvider)(progress, alreadyUnlocked: unlocked)
      .where(
        (m) =>
            m.unlocked &&
            m.estimatedDate.year == today.year &&
            m.estimatedDate.month == today.month &&
            m.estimatedDate.day == today.day,
      );
  return todays.isEmpty ? null : todays.last;
});

/// The furthest milestone that has just been reached but not yet celebrated,
/// or null.
///
/// Progress ticks once a second, so this recomputes only when one of the three
/// quantities a milestone can turn on — the whole percent, days served, days
/// left — actually changes, and the celebration listener fires at most once
/// per crossing.
final pendingCelebrationProvider = Provider.autoDispose<Milestone?>((ref) {
  final counts = ref.watch(
    serviceProgressProvider.select(
      (p) => p == null
          ? null
          : (percent: p.percentInt, served: p.daysServed, left: p.daysRemaining),
    ),
  );
  if (counts == null) return null;

  final progress = ref.read(serviceProgressProvider);
  if (progress == null) return null;

  final soldierId = ref.watch(activeSoldierProvider.select((s) => s?.id));
  final unlocked = ref.watch(
    settingsControllerProvider.select((s) => s.milestonesOf(soldierId)),
  );

  // The list is date-ordered, so the last pending entry is the furthest one
  // reached — the one worth celebrating when several land together.
  final newly = ref
      .read(computeMilestonesProvider)(progress, alreadyUnlocked: unlocked)
      .where((m) => m.justUnlocked);
  return newly.isEmpty ? null : newly.last;
});
