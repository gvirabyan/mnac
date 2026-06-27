import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Reusable premium gradients for backgrounds and accent glows.
abstract final class AppGradients {
  AppGradients._();

  /// Soft warm background for light theme.
  static const LinearGradient lightBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.surfaceLight, AppColors.beige],
  );

  /// Deep, calm background for dark theme.
  static const LinearGradient darkBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.surfaceDark, AppColors.charcoalDeep],
  );

  /// A subtle glow built from an accent color, for hero cards.
  static RadialGradient accentGlow(Color accent) => RadialGradient(
        center: Alignment.topCenter,
        radius: 1.1,
        colors: [
          accent.withValues(alpha: 0.22),
          accent.withValues(alpha: 0.0),
        ],
      );

  /// Sweep used by the circular countdown progress arc.
  static SweepGradient countdownSweep(Color accent) => SweepGradient(
        startAngle: 0,
        endAngle: 3.1415926 * 2,
        colors: [
          accent.withValues(alpha: 0.85),
          accent,
          accent.withValues(alpha: 0.85),
        ],
      );
}
