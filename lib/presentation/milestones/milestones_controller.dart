import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/service_constants.dart';
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

/// The highest threshold that has just been reached but not yet celebrated,
/// or null. Recomputes only when the integer percent or the persisted set
/// changes, so the celebration listener fires at most once per crossing.
final pendingCelebrationProvider = Provider.autoDispose<int?>((ref) {
  final percentInt = ref.watch(
    serviceProgressProvider.select((p) => p?.percentInt ?? -1),
  );
  final unlocked = ref.watch(
    settingsControllerProvider.select((s) => s.unlockedMilestones),
  );

  final newly = ServiceConstants.milestoneThresholds
      .where((t) => percentInt >= t && !unlocked.contains(t))
      .toList();
  if (newly.isEmpty) return null;
  return newly.reduce(math.max);
});
