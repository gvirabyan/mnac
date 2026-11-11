import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/di/providers.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/milestone.dart';
import '../../domain/entities/soldier_profile.dart';
import '../shared/state/settings_controller.dart';
import '../shared/state/soldiers_controller.dart';

/// Opens the editor for one of the active soldier's own achievements: a new
/// one, or [existing] to change or delete it. Saves on its own.
Future<void> showCustomMilestoneEditor(
  BuildContext context,
  WidgetRef ref, {
  CustomMilestone? existing,
}) async {
  final soldier = ref.read(activeSoldierProvider);
  if (soldier == null) return;

  final result = await showDialog<_EditorResult>(
    context: context,
    builder: (_) => _CustomMilestoneDialog(soldier: soldier, existing: existing),
  );
  if (result == null) return;

  final others = soldier.customMilestones
      .where((c) => c.id != existing?.id)
      .toList();
  final edited = result.milestone;
  final milestones = edited == null
      ? others
      : [
          // An edit keeps its place in the list; a new one goes last.
          for (final c in soldier.customMilestones)
            c.id == edited.id ? edited : c,
          if (existing == null) edited,
        ];

  final settings = ref.read(settingsControllerProvider.notifier);
  if (edited != null) {
    final today = AppDateUtils.dateOnly(DateTime.now());
    if (edited.date.isBefore(today)) {
      // A day already gone is filed as reached, not celebrated: confetti for
      // something that happened weeks ago would only puzzle. Recorded before
      // the save, so the celebration listener never sees it as new.
      await settings.markMilestonesUnlocked(soldier.id, {edited.milestoneId});
    }
  }

  final updated = soldier.copyWith(customMilestones: milestones);
  await ref.read(soldiersControllerProvider.notifier).addOrUpdate(updated);

  // A date moved into the future must be able to open again when it comes
  // round; forgetting what is no longer reached does that, as the soldier
  // form does when the service dates change.
  final progress =
      ref.read(computeServiceProgressProvider)(updated, DateTime.now());
  await settings.forgetMilestonesNotReached(
    soldier.id,
    ref.read(computeMilestonesProvider).unlockedIds(progress),
  );
}

/// What the dialog closed with: the achievement to save, or null to delete.
class _EditorResult {
  const _EditorResult(this.milestone);
  final CustomMilestone? milestone;
}

class _CustomMilestoneDialog extends StatefulWidget {
  const _CustomMilestoneDialog({required this.soldier, this.existing});

  final SoldierProfile soldier;
  final CustomMilestone? existing;

  @override
  State<_CustomMilestoneDialog> createState() => _CustomMilestoneDialogState();
}

class _CustomMilestoneDialogState extends State<_CustomMilestoneDialog> {
  static const _uuid = Uuid();
  static const _maxTitleLength = 40;

  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.title ?? '');
  late DateTime _date = widget.existing?.date ?? _clampToService(DateTime.now());
  String? _error;

  DateTime get _first => AppDateUtils.dateOnly(widget.soldier.serviceStart);
  DateTime get _last => AppDateUtils.dateOnly(widget.soldier.dischargeDate);

  /// Today if it falls within the service, otherwise its nearest end.
  DateTime _clampToService(DateTime d) {
    final day = AppDateUtils.dateOnly(d);
    if (day.isBefore(_first)) return _first;
    if (day.isAfter(_last)) return _last;
    return day;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _clampToService(_date),
      firstDate: _first,
      lastDate: _last,
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = AppStrings.customMilestoneNameRequired);
      return;
    }
    final existing = widget.existing;
    final milestone = existing == null
        ? CustomMilestone(id: _uuid.v4(), title: title, date: _date)
        : existing.copyWith(title: title, date: _date);
    Navigator.of(context).pop(_EditorResult(milestone));
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.customMilestoneDeleteTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop(const _EditorResult(null));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(
        isEdit
            ? AppStrings.customMilestoneEditTitle
            : AppStrings.customMilestoneAddTitle,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _title,
            autofocus: !isEdit,
            maxLength: _maxTitleLength,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              hintText: AppStrings.customMilestoneNameHint,
              errorText: _error,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(AppStrings.customMilestoneDate, style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSizes.xs),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_rounded, size: 18),
            label: Text(AppDateUtils.formatLong(_date)),
          ),
        ],
      ),
      actions: [
        if (isEdit)
          TextButton(
            onPressed: _delete,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(AppStrings.delete),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(AppStrings.save)),
      ],
    );
  }
}
