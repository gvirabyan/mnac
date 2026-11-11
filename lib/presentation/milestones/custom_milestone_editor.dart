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

  final result = await showModalBottomSheet<_EditorResult>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _CustomMilestoneSheet(soldier: soldier, existing: existing),
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

/// What the sheet closed with: the achievement to save, or null to delete.
class _EditorResult {
  const _EditorResult(this.milestone);
  final CustomMilestone? milestone;
}

class _CustomMilestoneSheet extends StatefulWidget {
  const _CustomMilestoneSheet({required this.soldier, this.existing});

  final SoldierProfile soldier;
  final CustomMilestone? existing;

  @override
  State<_CustomMilestoneSheet> createState() => _CustomMilestoneSheetState();
}

class _CustomMilestoneSheetState extends State<_CustomMilestoneSheet> {
  static const _uuid = Uuid();
  static const _maxTitleLength = 40;

  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.title ?? '');
  late DateTime _date =
      widget.existing?.date ?? _clampToService(DateTime.now());
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
  void initState() {
    super.initState();
    // Rebuilt on every keystroke so the chips can show which one is picked.
    _title.addListener(_onTitleChanged);
  }

  void _onTitleChanged() => setState(() => _error = null);

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _useSuggestion(String text) {
    _title.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
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

  /// Under the date: which day of the service it is, and how far off.
  String get _dateDetail {
    final serviceDay = AppDateUtils.daysBetween(_first, _date) + 1;
    final today = AppDateUtils.dateOnly(DateTime.now());
    final parts = [
      AppStrings.customMilestoneServiceDay(serviceDay),
      if (!_date.isBefore(today))
        AppStrings.milestoneInDays(AppDateUtils.daysBetween(today, _date)),
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final isEdit = widget.existing != null;
    final fieldRadius = BorderRadius.circular(AppSizes.radiusSm);
    final typed = _title.text.trim();

    return Padding(
      // Lifts the sheet above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          0,
          AppSizes.screenPadding,
          AppSizes.lg + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.16),
                  ),
                  child: Icon(Icons.flag_rounded, color: accent),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    isEdit
                        ? AppStrings.customMilestoneEditTitle
                        : AppStrings.customMilestoneAddTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (isEdit)
                  IconButton(
                    tooltip: AppStrings.delete,
                    onPressed: _delete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            TextField(
              controller: _title,
              autofocus: !isEdit,
              maxLength: _maxTitleLength,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              style: theme.textTheme.titleMedium,
              decoration: InputDecoration(
                hintText: AppStrings.customMilestoneNameHint,
                errorText: _error,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                prefixIcon: const Icon(Icons.edit_outlined),
                border: OutlineInputBorder(
                  borderRadius: fieldRadius,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: fieldRadius,
                  borderSide: BorderSide(color: accent, width: 1.5),
                ),
              ),
            ),
            Wrap(
              spacing: AppSizes.xs,
              runSpacing: AppSizes.xs,
              children: [
                for (final s in AppStrings.customMilestoneSuggestions)
                  ChoiceChip(
                    label: Text(s),
                    selected: typed == s,
                    onSelected: (_) => _useSuggestion(s),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              AppStrings.customMilestoneDate,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            Material(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: fieldRadius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _pickDate,
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Row(
                    children: [
                      Icon(Icons.event_rounded, color: accent),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppDateUtils.formatLong(_date),
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _dateDetail,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.outline,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            FilledButton.icon(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: fieldRadius),
              ),
              icon: const Icon(Icons.check_rounded),
              label: Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }
}
