import '../../domain/entities/app_settings.dart';

/// Data-layer representation of [AppSettings] with JSON (de)serialization.
class AppSettingsModel {
  const AppSettingsModel(this.settings);

  final AppSettings settings;

  Map<String, dynamic> toJson() => {
        'themeMode': settings.themeMode.id,
        'accentColorId': settings.accentColorId,
        'fontScaleId': settings.fontScaleId,
        'animationLevel': settings.animationLevel.id,
        'backgroundImagePath': settings.backgroundImagePath,
        'notificationsEnabled': settings.notificationsEnabled,
        'dailyReminderEnabled': settings.dailyReminderEnabled,
        'dailyReminderMinutes': settings.dailyReminderMinutes,
        'milestoneNotificationsEnabled': settings.milestoneNotificationsEnabled,
        'unlockedMilestones': {
          for (final entry in settings.unlockedMilestones.entries)
            entry.key: entry.value.toList()..sort(),
        },
      };

  /// Reads one entry of a persisted unlocked set.
  ///
  /// Milestones used to be identified by their percent threshold alone, so a
  /// set written by an older build holds bare numbers; those map onto the
  /// percent ids of the catalogue. Anything else is dropped rather than
  /// guessed at.
  static String? _milestoneId(Object? raw) => switch (raw) {
        final num n => 'pct${n.toInt()}',
        final String id => id,
        _ => null,
      };

  static Set<String> _milestoneIds(Object? raw) =>
      (raw as List?)?.map(_milestoneId).nonNulls.toSet() ?? const <String>{};

  /// Reads the unlocked milestones in either shape they have been written in.
  ///
  /// A map is the current one, keyed by soldier id. A bare list comes from a
  /// build that tracked milestones for the app as a whole; it is parked under
  /// [AppSettings.legacyMilestonesKey] for the controller to hand to the
  /// soldier who was active when it was written.
  static Map<String, Set<String>> _unlockedMilestones(Object? raw) =>
      switch (raw) {
        final Map<dynamic, dynamic> bySoldier => {
            for (final entry in bySoldier.entries)
              '${entry.key}': _milestoneIds(entry.value),
          },
        final List<dynamic> flat when flat.isNotEmpty => {
            AppSettings.legacyMilestonesKey: _milestoneIds(flat),
          },
        _ => const <String, Set<String>>{},
      };

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      AppSettings(
        themeMode: AppThemeMode.fromId(json['themeMode'] as String?),
        accentColorId: json['accentColorId'] as String? ?? 'apricot',
        fontScaleId: json['fontScaleId'] as String? ?? 'medium',
        animationLevel: AnimationLevel.fromId(json['animationLevel'] as String?),
        backgroundImagePath: json['backgroundImagePath'] as String?,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
        dailyReminderEnabled: json['dailyReminderEnabled'] as bool? ?? false,
        dailyReminderMinutes:
            (json['dailyReminderMinutes'] as num?)?.toInt() ?? 19 * 60,
        milestoneNotificationsEnabled:
            json['milestoneNotificationsEnabled'] as bool? ?? true,
        unlockedMilestones: _unlockedMilestones(json['unlockedMilestones']),
      ),
    );
  }
}
