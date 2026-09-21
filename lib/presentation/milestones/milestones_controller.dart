import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/milestone.dart';
import '../home/home_controller.dart';
import '../shared/state/settings_controller.dart';

/// The full milestone list for the milestones screen (recomputed each tick).
final milestonesProvider = Provider.autoDispose<List<Milestone>>((ref) {
  final progress = ref.watch(serviceProgressProvider);
  if (progress == null) return const [];
  final unlocked = ref.watch(
    settingsControllerProvider.select((s) => s.unlockedMilestones),
  );
  return ref.watch(computeMilestonesProvider)(
    progress,
    alreadyUnlocked: unlocked,
  );
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

  final unlocked = ref.watch(
    settingsControllerProvider.select((s) => s.unlockedMilestones),
  );

  // The list is date-ordered, so the last pending entry is the furthest one
  // reached — the one worth celebrating when several land together.
  final newly = ref
      .read(computeMilestonesProvider)(progress, alreadyUnlocked: unlocked)
      .where((m) => m.justUnlocked);
  return newly.isEmpty ? null : newly.last;
});
