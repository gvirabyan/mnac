import 'package:flutter/material.dart';

import 'app_colors.dart';

/// A selectable accent color the user can pick in personalization.
class AccentOption {
  const AccentOption(this.id, this.color);

  /// Stable id persisted in settings.
  final String id;
  final Color color;
}

/// Available accent colors. The first entry is the default (apricot/gold).
abstract final class AccentPalette {
  AccentPalette._();

  static const AccentOption apricot = AccentOption('apricot', AppColors.apricot);
  static const AccentOption red = AccentOption('red', AppColors.flagRed);
  static const AccentOption blue = AccentOption('blue', AppColors.flagBlue);
  static const AccentOption plum = AccentOption('plum', Color(0xFF7B4B6B));
  static const AccentOption forest = AccentOption('forest', Color(0xFF5B7553));
  static const AccentOption copper = AccentOption('copper', Color(0xFFB66E41));

  static const List<AccentOption> all = [
    apricot,
    red,
    blue,
    plum,
    forest,
    copper,
  ];

  static const AccentOption fallback = apricot;

  /// Resolves an accent option from its persisted [id].
  static AccentOption fromId(String? id) {
    if (id == null) return fallback;
    for (final option in all) {
      if (option.id == id) return option;
    }
    return fallback;
  }
}
