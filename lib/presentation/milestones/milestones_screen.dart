import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/l10n/app_strings.dart';
import '../shared/widgets/app_loading.dart';
import '../shared/widgets/gradient_scaffold.dart';
import 'milestones_controller.dart';
import 'widgets/milestone_card.dart';

/// Milestones screen: the list of progress milestones with locked/unlocked
/// styling. Reachable from Home and Statistics.
class MilestonesScreen extends ConsumerWidget {
  const MilestonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestones = ref.watch(milestonesProvider);

    return GradientScaffold(
      appBar: AppBar(title: const Text(AppStrings.milestonesTitle)),
      body: milestones.isEmpty
          ? const AppLoading()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.md,
                AppSizes.screenPadding,
                AppSizes.xxl,
              ),
              itemCount: milestones.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSizes.md),
              itemBuilder: (context, index) =>
                  MilestoneCard(milestone: milestones[index]),
            ),
    );
  }
}
