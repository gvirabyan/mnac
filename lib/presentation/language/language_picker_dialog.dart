import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/l10n/app_language.dart';
import '../../core/l10n/app_strings.dart';
import '../shared/state/settings_controller.dart';

/// First-launch language picker: one row per language, each with its flag and
/// named in itself, so anyone finds their own whatever the phone is set to.
///
/// Cannot be dismissed without a choice — picking is what saves the settings,
/// and so what keeps the picker from showing on the next launch. The phone's
/// language (already applied in `main`) is highlighted as the suggestion.
Future<void> showLanguagePicker(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: _LanguagePickerDialog(),
    ),
  );
}

class _LanguagePickerDialog extends ConsumerWidget {
  const _LanguagePickerDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final current =
        ref.watch(settingsControllerProvider.select((s) => s.language));

    return AlertDialog(
      icon: Icon(Icons.language_rounded, color: theme.colorScheme.primary),
      title: Text(AppStrings.chooseLanguageTitle, textAlign: TextAlign.center),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.md,
        AppSizes.md,
        AppSizes.lg,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final language in AppLanguage.values)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.xs),
              child: _LanguageTile(
                language: language,
                selected: language == current,
                onTap: () async {
                  await ref
                      .read(settingsControllerProvider.notifier)
                      .setLanguage(language);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppSizes.radiusMd);

    return Material(
      color: selected
          ? scheme.primaryContainer
          : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: selected ? scheme.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
          child: Row(
            children: [
              Text(
                AppStrings.languageFlag(language),
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Text(
                  AppStrings.languageName(language),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: selected ? scheme.onPrimaryContainer : null,
                      ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
