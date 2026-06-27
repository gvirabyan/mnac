/// How the app resolves light/dark appearance.
enum AppThemeMode {
  system('system'),
  light('light'),
  dark('dark');

  const AppThemeMode(this.id);
  final String id;

  static AppThemeMode fromId(String? id) =>
      AppThemeMode.values.firstWhere((m) => m.id == id, orElse: () => system);
}

/// Controls how much motion the UI uses, honoring the user's preference.
enum AnimationLevel {
  none('none'),
  reduced('reduced'),
  full('full');

  const AnimationLevel(this.id);
  final String id;

  static AnimationLevel fromId(String? id) =>
      AnimationLevel.values.firstWhere((l) => l.id == id, orElse: () => full);
}

/// User preferences. Pure domain entity.
///
/// [accentColorId] and [fontScaleId] are stable string ids resolved to concrete
/// values in the presentation layer, keeping the domain free of UI types.
class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.accentColorId = 'apricot',
    this.fontScaleId = 'medium',
    this.animationLevel = AnimationLevel.full,
    this.backgroundImagePath,
    this.notificationsEnabled = false,
    this.dailyReminderEnabled = false,
    this.dailyReminderMinutes = 19 * 60, // 19:00, minutes since midnight
    this.milestoneNotificationsEnabled = true,
    this.unlockedMilestones = const <int>{},
  });

  final AppThemeMode themeMode;
  final String accentColorId;
  final String fontScaleId;
  final AnimationLevel animationLevel;
  final String? backgroundImagePath;
  final bool notificationsEnabled;
  final bool dailyReminderEnabled;

  /// Daily reminder time expressed as minutes since midnight.
  final int dailyReminderMinutes;
  final bool milestoneNotificationsEnabled;

  /// Set of milestone thresholds (e.g. 25, 50) already celebrated.
  final Set<int> unlockedMilestones;

  static const AppSettings defaults = AppSettings();

  AppSettings copyWith({
    AppThemeMode? themeMode,
    String? accentColorId,
    String? fontScaleId,
    AnimationLevel? animationLevel,
    String? backgroundImagePath,
    bool? notificationsEnabled,
    bool? dailyReminderEnabled,
    int? dailyReminderMinutes,
    bool? milestoneNotificationsEnabled,
    Set<int>? unlockedMilestones,
    bool clearBackgroundImage = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColorId: accentColorId ?? this.accentColorId,
      fontScaleId: fontScaleId ?? this.fontScaleId,
      animationLevel: animationLevel ?? this.animationLevel,
      backgroundImagePath: clearBackgroundImage
          ? null
          : (backgroundImagePath ?? this.backgroundImagePath),
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderMinutes: dailyReminderMinutes ?? this.dailyReminderMinutes,
      milestoneNotificationsEnabled:
          milestoneNotificationsEnabled ?? this.milestoneNotificationsEnabled,
      unlockedMilestones: unlockedMilestones ?? this.unlockedMilestones,
    );
  }
}
