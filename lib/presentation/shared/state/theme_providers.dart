import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/accent_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/app_settings.dart';
import 'settings_controller.dart';

/// Resolves the selected accent color from settings.
final accentColorProvider = Provider<Color>((ref) {
  final id = ref.watch(
    settingsControllerProvider.select((s) => s.accentColorId),
  );
  return AccentPalette.fromId(id).color;
});

/// Resolves the font scale factor from settings.
final fontScaleProvider = Provider<double>((ref) {
  final id = ref.watch(
    settingsControllerProvider.select((s) => s.fontScaleId),
  );
  return FontScale.fromId(id).factor;
});

final lightThemeProvider = Provider<ThemeData>((ref) {
  return AppTheme.light(
    accent: ref.watch(accentColorProvider),
    fontScale: ref.watch(fontScaleProvider),
  );
});

final darkThemeProvider = Provider<ThemeData>((ref) {
  return AppTheme.dark(
    accent: ref.watch(accentColorProvider),
    fontScale: ref.watch(fontScaleProvider),
  );
});

/// Maps the domain theme mode onto Flutter's [ThemeMode].
final themeModeProvider = Provider<ThemeMode>((ref) {
  final mode = ref.watch(
    settingsControllerProvider.select((s) => s.themeMode),
  );
  return switch (mode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
});
