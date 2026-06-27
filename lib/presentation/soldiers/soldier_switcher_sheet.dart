import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/app_router.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/di/providers.dart';
import '../../core/l10n/app_strings.dart';
import '../../domain/entities/soldier_profile.dart';
import '../shared/state/soldiers_controller.dart';
import '../soldier_form/soldier_form_screen.dart';

/// Opens the bottom sheet for switching between soldiers, editing, deleting,
/// and adding a new one.
Future<void> showSoldierSwitcher(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _SoldierSwitcherSheet(),
  );
}

class _SoldierSwitcherSheet extends ConsumerWidget {
  const _SoldierSwitcherSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(soldiersControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.lg,
          0,
          AppSizes.lg,
          AppSizes.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.soldiersTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSizes.md),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: state.soldiers.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSizes.xs),
                itemBuilder: (context, index) {
                  final soldier = state.soldiers[index];
                  return _SoldierRow(
                    soldier: soldier,
                    active: soldier.id == state.activeId,
                  );
                },
              ),
            ),
            const SizedBox(height: AppSizes.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context)
                      .push(appPageRoute(const SoldierFormScreen()));
                },
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text(AppStrings.soldiersAdd),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoldierRow extends ConsumerWidget {
  const _SoldierRow({required this.soldier, required this.active});

  final SoldierProfile soldier;
  final bool active;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.soldierDeleteTitle),
        content: const Text(AppStrings.soldierDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(soldiersControllerProvider.notifier).delete(soldier.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasPhoto =
        soldier.photoPath != null && File(soldier.photoPath!).existsSync();
    final progress =
        ref.read(computeServiceProgressProvider)(soldier, DateTime.now());

    return Material(
      color: active
          ? theme.colorScheme.primary.withValues(alpha: 0.12)
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        onTap: () {
          ref.read(soldiersControllerProvider.notifier).setActive(soldier.id);
          Navigator.of(context).pop();
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.sm),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.surface,
                backgroundImage:
                    hasPhoto ? FileImage(File(soldier.photoPath!)) : null,
                child: hasPhoto
                    ? null
                    : Icon(Icons.person_rounded,
                        color: theme.colorScheme.primary),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      soldier.name ?? AppStrings.soldierUnnamed,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      active
                          ? '${AppStrings.soldierActive} · ${progress.percentInt}%'
                          : '${progress.percentInt}%',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: AppStrings.settingsEditProfile,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    appPageRoute(SoldierFormScreen(existing: soldier)),
                  );
                },
              ),
              IconButton(
                tooltip: AppStrings.delete,
                icon: Icon(Icons.delete_outline,
                    color: theme.colorScheme.error),
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
