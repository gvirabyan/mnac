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
        'unlockedMilestones': settings.unlockedMilestones.toList()..sort(),
      };

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    final unlocked = (json['unlockedMilestones'] as List?)
            ?.map((e) => (e as num).toInt())
            .toSet() ??
        const <int>{};

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
        unlockedMilestones: unlocked,
      ),
    );
  }
}
