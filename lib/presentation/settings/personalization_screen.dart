import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/l10n/app_strings.dart';
import '../../domain/entities/app_settings.dart';
import '../shared/state/settings_controller.dart';
import '../shared/widgets/glass_card.dart';
import '../shared/widgets/gradient_scaffold.dart';
import '../shared/widgets/section_header.dart';
import 'widgets/accent_picker.dart';
import 'widgets/option_segments.dart';

/// App-level personalization: theme, accent, font size, and animation level.
/// (Per-soldier visuals — the photo, which is also the home background — live in
/// the soldier form.)
class PersonalizationScreen extends ConsumerWidget {
  const PersonalizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final settingsCtrl = ref.read(settingsControllerProvider.notifier);

    return GradientScaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsPersonalization)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          AppSizes.md,
          AppSizes.screenPadding,
          AppSizes.xxl,
        ),
        children: [
          _Section(
            title: AppStrings.persTheme,
            child: OptionSegments<AppThemeMode>(
              selected: settings.themeMode,
              onChanged: settingsCtrl.setThemeMode,
              options: const [
                SegmentOption(AppThemeMode.system, AppStrings.persThemeSystem),
                SegmentOption(AppThemeMode.light, AppStrings.persThemeLight),
                SegmentOption(AppThemeMode.dark, AppStrings.persThemeDark),
              ],
            ),
          ),
          _Section(
            title: AppStrings.persAccent,
            child: AccentPicker(
              selectedId: settings.accentColorId,
              onSelected: settingsCtrl.setAccent,
            ),
          ),
          _Section(
            title: AppStrings.persFontSize,
            child: OptionSegments<String>(
              selected: settings.fontScaleId,
              onChanged: settingsCtrl.setFontScale,
              options: const [
                SegmentOption('small', AppStrings.persFontSmall),
                SegmentOption('medium', AppStrings.persFontMedium),
                SegmentOption('large', AppStrings.persFontLarge),
              ],
            ),
          ),
          _Section(
            title: AppStrings.persAnimationLevel,
            child: OptionSegments<AnimationLevel>(
              selected: settings.animationLevel,
              onChanged: settingsCtrl.setAnimationLevel,
              options: const [
                SegmentOption(AnimationLevel.none, AppStrings.persAnimNone),
                SegmentOption(AnimationLevel.reduced, AppStrings.persAnimReduced),
                SegmentOption(AnimationLevel.full, AppStrings.persAnimFull),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          const SizedBox(height: AppSizes.md),
          GlassCard(child: child),
        ],
      ),
    );
  }
}
