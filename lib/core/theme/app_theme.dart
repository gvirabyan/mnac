import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Builds the light and dark [ThemeData] for the app, parameterized by the
/// user's chosen accent color and font scale.
abstract final class AppTheme {
  AppTheme._();

  static ThemeData light({
    required Color accent,
    double fontScale = 1.0,
  }) {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: accent,
      onPrimary: _onAccent(accent),
      secondary: accent,
      onSecondary: _onAccent(accent),
      surface: AppColors.surfaceLight,
      onSurface: AppColors.charcoal,
      surfaceContainerHighest: AppColors.cardLight,
      error: AppColors.danger,
      onError: Colors.white,
      outline: AppColors.outlineLight,
    );

    return _base(
      colorScheme: colorScheme,
      muted: AppColors.mutedLight,
      fontScale: fontScale,
      scaffold: AppColors.surfaceLight,
      card: AppColors.cardLight,
    );
  }

  static ThemeData dark({
    required Color accent,
    double fontScale = 1.0,
  }) {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: accent,
      onPrimary: _onAccent(accent),
      secondary: accent,
      onSecondary: _onAccent(accent),
      surface: AppColors.surfaceDark,
      onSurface: AppColors.offWhite,
      surfaceContainerHighest: AppColors.cardDark,
      error: AppColors.danger,
      onError: Colors.white,
      outline: AppColors.outlineDark,
    );

    return _base(
      colorScheme: colorScheme,
      muted: AppColors.mutedDark,
      fontScale: fontScale,
      scaffold: AppColors.surfaceDark,
      card: AppColors.cardDark,
    );
  }

  static ThemeData _base({
    required ColorScheme colorScheme,
    required Color muted,
    required double fontScale,
    required Color scaffold,
    required Color card,
  }) {
    final textTheme = AppTypography.build(
      onSurface: colorScheme.onSurface,
      muted: muted,
      scale: fontScale,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
        foregroundColor: colorScheme.onSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(56),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: card,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
        space: AppSizes.lg,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: scaffold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
    );
  }

  /// Picks a readable foreground for text/icons placed on the accent color.
  static Color _onAccent(Color accent) =>
      accent.computeLuminance() > 0.55 ? AppColors.charcoal : Colors.white;
}
