import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/l10n/app_strings.dart';
import '../../domain/entities/milestone.dart';
import '../shared/state/soldiers_controller.dart';
import '../shared/widgets/app_loading.dart';
import '../shared/widgets/gradient_scaffold.dart';
import 'custom_milestone_editor.dart';
import 'milestones_controller.dart';
import 'widgets/milestone_card.dart';

/// Milestones screen: the list of progress milestones with locked/unlocked
/// styling, plus the user's own, which they add here and edit by tapping.
/// Reachable from Home and Statistics.
class MilestonesScreen extends ConsumerWidget {
  const MilestonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestones = ref.watch(milestonesProvider);
    final soldier = ref.watch(activeSoldierProvider);

    return GradientScaffold(
      appBar: AppBar(title: Text(AppStrings.milestonesTitle)),
      floatingActionButton: soldier == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showCustomMilestoneEditor(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: Text(AppStrings.customMilestoneAdd),
            ),
      body: milestones.isEmpty
          ? const AppLoading()
          : ListView.separated(
              // Room at the bottom for the button, so the last card can
              // scroll out from under it.
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.md,
                AppSizes.screenPadding,
                AppSizes.xxl + 72,
              ),
              itemCount: milestones.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSizes.md),
              itemBuilder: (context, index) {
                final milestone = milestones[index];
                final custom = milestone.kind == MilestoneKind.custom
                    ? soldier?.customMilestones
                        .where((c) => c.milestoneId == milestone.id)
                        .firstOrNull
                    : null;
                return MilestoneCard(
                  milestone: milestone,
                  onTap: custom == null
                      ? null
                      : () => showCustomMilestoneEditor(
                            context,
                            ref,
                            existing: custom,
                          ),
                );
              },
            ),
    );
  }
}
