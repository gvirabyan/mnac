import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../domain/entities/app_settings.dart';

/// Holds the live [AppSettings] and persists changes.
///
/// Seeded synchronously from [initialSettingsProvider] so the theme is correct
/// on first frame. Every mutation updates state immediately, then persists.
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(initialSettingsProvider);

  Future<void> _persist(AppSettings next) async {
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
  }

  Future<void> update(AppSettings Function(AppSettings current) transform) =>
      _persist(transform(state));

  Future<void> setThemeMode(AppThemeMode mode) =>
      _persist(state.copyWith(themeMode: mode));

  Future<void> setAccent(String accentColorId) =>
      _persist(state.copyWith(accentColorId: accentColorId));

  Future<void> setFontScale(String fontScaleId) =>
      _persist(state.copyWith(fontScaleId: fontScaleId));

  Future<void> setAnimationLevel(AnimationLevel level) =>
      _persist(state.copyWith(animationLevel: level));

  Future<void> setBackgroundImage(String? path) => _persist(
        path == null
            ? state.copyWith(clearBackgroundImage: true)
            : state.copyWith(backgroundImagePath: path),
      );

  Future<void> setNotificationsEnabled(bool enabled) =>
      _persist(state.copyWith(notificationsEnabled: enabled));

  Future<void> setDailyReminderEnabled(bool enabled) =>
      _persist(state.copyWith(dailyReminderEnabled: enabled));

  Future<void> setDailyReminderMinutes(int minutes) =>
      _persist(state.copyWith(dailyReminderMinutes: minutes));

  Future<void> setMilestoneNotifications(bool enabled) =>
      _persist(state.copyWith(milestoneNotificationsEnabled: enabled));

  /// Records that the given milestone thresholds have been celebrated.
  Future<void> markMilestonesUnlocked(Set<int> thresholds) {
    if (thresholds.every(state.unlockedMilestones.contains)) {
      return Future.value();
    }
    return _persist(
      state.copyWith(
        unlockedMilestones: {...state.unlockedMilestones, ...thresholds},
      ),
    );
  }

  /// Re-reads settings from storage (used after a restore).
  Future<void> reload() async {
    state = await ref.read(settingsRepositoryProvider).load();
  }

  /// Resets settings to defaults (used by the app reset flow).
  Future<void> resetToDefaults() => _persist(AppSettings.defaults);
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
