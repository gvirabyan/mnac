import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Selectable font scale (Small / Medium / Large).
enum FontScale {
  small('small', 0.9),
  medium('medium', 1.0),
  large('large', 1.12);

  const FontScale(this.id, this.factor);

  /// Stable id persisted in settings.
  final String id;

  /// Multiplier applied to the base text theme.
  final double factor;

  static FontScale fromId(String? id) =>
      FontScale.values.firstWhere((s) => s.id == id, orElse: () => medium);
}

/// Builds the app's text theme.
///
/// Display/headline styles use Noto Serif Armenian for an elegant, editorial
/// feel; body/label styles use Noto Sans Armenian for clean readability.
abstract final class AppTypography {
  AppTypography._();

  static TextTheme build({
    required Color onSurface,
    required Color muted,
    double scale = 1.0,
  }) {
    final serif = GoogleFonts.notoSerifArmenianTextTheme();
    final sans = GoogleFonts.notoSansArmenianTextTheme();

    TextStyle display(TextStyle? base, double size, FontWeight weight) =>
        (base ?? const TextStyle()).copyWith(
          fontSize: size * scale,
          fontWeight: weight,
          color: onSurface,
          height: 1.05,
          letterSpacing: -0.5,
        );

    TextStyle body(TextStyle? base, double size, FontWeight weight,
            {Color? color}) =>
        (base ?? const TextStyle()).copyWith(
          fontSize: size * scale,
          fontWeight: weight,
          color: color ?? onSurface,
          height: 1.35,
        );

    return TextTheme(
      displayLarge: display(serif.displayLarge, 57, FontWeight.w700),
      displayMedium: display(serif.displayMedium, 45, FontWeight.w700),
      displaySmall: display(serif.displaySmall, 36, FontWeight.w600),
      headlineLarge: display(serif.headlineLarge, 32, FontWeight.w600),
      headlineMedium: display(serif.headlineMedium, 28, FontWeight.w600),
      headlineSmall: display(serif.headlineSmall, 24, FontWeight.w600),
      titleLarge: body(sans.titleLarge, 22, FontWeight.w600),
      titleMedium: body(sans.titleMedium, 16, FontWeight.w600),
      titleSmall: body(sans.titleSmall, 14, FontWeight.w600),
      bodyLarge: body(sans.bodyLarge, 16, FontWeight.w400),
      bodyMedium: body(sans.bodyMedium, 14, FontWeight.w400),
      bodySmall: body(sans.bodySmall, 12, FontWeight.w400, color: muted),
      labelLarge: body(sans.labelLarge, 14, FontWeight.w600),
      labelMedium: body(sans.labelMedium, 12, FontWeight.w600),
      labelSmall: body(sans.labelSmall, 11, FontWeight.w500, color: muted),
    );
  }
}
