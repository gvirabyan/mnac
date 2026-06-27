import 'package:flutter/material.dart';

/// Core color palette.
///
/// Inspired by Armenia — warm beige, soft white, charcoal, and flag accents
/// (apricot/gold, red, blue) — deliberately avoiding dark-green military cliché.
abstract final class AppColors {
  AppColors._();

  // Neutrals — light.
  static const Color beige = Color(0xFFF4ECE1);
  static const Color surfaceLight = Color(0xFFFBF8F3);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF1E1B16);
  static const Color mutedLight = Color(0xFF8A8276);
  static const Color outlineLight = Color(0xFFE4DACB);

  // Neutrals — dark.
  static const Color charcoalDeep = Color(0xFF14110D);
  static const Color surfaceDark = Color(0xFF1A1714);
  static const Color cardDark = Color(0xFF221E1A);
  static const Color offWhite = Color(0xFFF1EADD);
  static const Color mutedDark = Color(0xFF9C9384);
  static const Color outlineDark = Color(0xFF332E27);

  // Armenian flag accents.
  static const Color apricot = Color(0xFFF2A900); // primary accent (gold/apricot)
  static const Color flagRed = Color(0xFFD90012);
  static const Color flagBlue = Color(0xFF0033A0);

  // Semantic.
  static const Color success = Color(0xFF3FA66A);
  static const Color danger = Color(0xFFD64545);

  // Translucent overlays for glassmorphism.
  static const Color glassLight = Color(0x66FFFFFF);
  static const Color glassDark = Color(0x33FFFFFF);
}
