import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/constants/service_constants.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/soldier_profile.dart';
import '../shared/state/soldiers_controller.dart';
import '../shared/widgets/glass_card.dart';
import '../shared/widgets/gradient_scaffold.dart';
import '../shared/widgets/primary_button.dart';
import '../shared/widgets/section_header.dart';
import 'widgets/photo_picker_tile.dart';

/// A single-screen form to add a new soldier or edit the existing one.
///
/// Captures a profile photo (optional) and the service period as two dates —
/// start and discharge. Picking a start date auto-fills the discharge date to
/// 1.5 years (Armenia's current service length); the discharge date can then be
/// changed freely.
class SoldierFormScreen extends ConsumerStatefulWidget {
  const SoldierFormScreen({super.key, this.existing});

  /// The profile to edit, or null to create a new one.
  final SoldierProfile? existing;

  @override
  ConsumerState<SoldierFormScreen> createState() => _SoldierFormScreenState();
}

class _SoldierFormScreenState extends ConsumerState<SoldierFormScreen> {
  static const _uuid = Uuid();

  final TextEditingController _nameController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;
  late String? _photoPath;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name ?? '';
      _startDate = existing.serviceStart;
      _endDate = existing.dischargeDate;
      _photoPath = existing.photoPath;
    } else {
      _startDate = DateTime.now();
      _endDate = AppDateUtils.addMonths(
        _startDate,
        ServiceConstants.defaultServiceMonths,
      );
      _photoPath = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate.isAfter(now) ? now : _startDate,
      firstDate: DateTime(now.year - 6),
      lastDate: now,
      locale: const Locale('hy'),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Auto-fill discharge to +1.5 years (still editable below).
        _endDate = AppDateUtils.addMonths(
          picked,
          ServiceConstants.defaultServiceMonths,
        );
      });
    }
  }

  Future<void> _pickEndDate() async {
    final initial =
        _endDate.isAfter(_startDate) ? _endDate : _startDate.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _startDate.add(const Duration(days: 1)),
      lastDate: _startDate.add(
        const Duration(days: ServiceConstants.maxServiceDays),
      ),
      locale: const Locale('hy'),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.errNameRequired)),
      );
      return;
    }
    if (!_endDate.isAfter(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.errEndBeforeStart)),
      );
      return;
    }
    final durationDays = _endDate.difference(_startDate).inDays;

    final SoldierProfile profile;
    if (_isEdit) {
      profile = widget.existing!.copyWith(
        name: name,
        serviceStart: _startDate,
        serviceDurationDays: durationDays,
        photoPath: _photoPath,
        clearPhoto: _photoPath == null,
      );
    } else {
      profile = SoldierProfile(
        id: _uuid.v4(),
        name: name,
        serviceStart: _startDate,
        serviceDurationDays: durationDays,
        photoPath: _photoPath,
        createdAt: DateTime.now(),
      );
    }

    await ref.read(soldiersControllerProvider.notifier).addOrUpdate(profile);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? AppStrings.settingsEditProfile : AppStrings.formAddTitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          AppSizes.md,
          AppSizes.screenPadding,
          AppSizes.xxl,
        ),
        children: [
          Center(
            child: PhotoPickerTile(
              photoPath: _photoPath,
              onChanged: (path) => setState(() => _photoPath = path),
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          const SectionHeader(title: AppStrings.formNameTitle),
          const SizedBox(height: AppSizes.md),
          _NameField(controller: _nameController, onSubmitted: (_) => _save()),
          const SizedBox(height: AppSizes.xl),
          const SectionHeader(title: AppStrings.formStartTitle),
          const SizedBox(height: AppSizes.md),
          _DateField(date: _startDate, onTap: _pickStartDate),
          const SizedBox(height: AppSizes.xl),
          const SectionHeader(title: AppStrings.formEndTitle),
          const SizedBox(height: AppSizes.md),
          _DateField(
            date: _endDate,
            icon: Icons.flag_rounded,
            onTap: _pickEndDate,
          ),
          const SizedBox(height: AppSizes.xxl),
          PrimaryButton(label: AppStrings.save, onPressed: _save),
        ],
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller, this.onSubmitted});

  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Row(
        children: [
          Icon(Icons.person_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: onSubmitted,
              style: theme.textTheme.titleMedium,
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: AppStrings.formNameHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.date,
    required this.onTap,
    this.icon = Icons.calendar_month_rounded,
  });

  final DateTime date;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              AppDateUtils.formatLong(date),
              style: theme.textTheme.titleMedium,
            ),
          ),
          Icon(Icons.edit_outlined,
              size: AppSizes.iconSm, color: theme.colorScheme.outline),
        ],
      ),
    );
  }
}
