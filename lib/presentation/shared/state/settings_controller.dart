import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../domain/entities/app_settings.dart';

/// Holds the live [AppSettings] and persists changes.
///
/// Seeded synchronously from [initialSettingsProvider] so the theme is correct
/// on first frame. Every mutation updates state immediately, then persists.
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final initial = ref.watch(initialSettingsProvider);
    final migrated = _withLegacyMilestonesAttributed(initial);
    if (!identical(migrated, initial)) {
      // build() has to stay synchronous, so the rewritten settings are saved
      // on the next microtask rather than awaited here.
      Future<void>.microtask(
        () => ref.read(settingsRepositoryProvider).save(migrated),
      );
    }
    return migrated;
  }

  /// Hands a pre-per-soldier unlocked set to the soldier who was active when
  /// it was written — the only profile that could have earned it.
  ///
  /// With no active soldier there is nobody to attribute it to, and keeping it
  /// would mean the next profile created inherits somebody else's
  /// achievements, so it is dropped.
  AppSettings _withLegacyMilestonesAttributed(AppSettings settings) {
    final legacy =
        settings.unlockedMilestones[AppSettings.legacyMilestonesKey];
    if (legacy == null) return settings;

    final bySoldier = {...settings.unlockedMilestones}
      ..remove(AppSettings.legacyMilestonesKey);
    final activeId = ref.read(initialActiveIdProvider);
    if (activeId != null) {
      bySoldier[activeId] = {...legacy, ...?bySoldier[activeId]};
    }
    return settings.copyWith(unlockedMilestones: bySoldier);
  }

  Future<void> _persist(AppSettings next) async {
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
  }

  Future<void> update(AppSettings Function(AppSettings current) transform) =>
      _persist(transform(state));

  Future<void> setThemeMode(AppThemeMode mode) =>
      _persist(state.copyWith(themeMode: mode));

  Future<void> setBackgroundImage(String? path) => _persist(
        path == null
            ? state.copyWith(clearBackgroundImage: true)
            : state.copyWith(backgroundImagePath: path),
      );

  Future<void> setNotificationsEnabled(bool enabled) =>
      _persist(state.copyWith(notificationsEnabled: enabled));

  /// Records that [soldierId] has celebrated the given milestones.
  Future<void> markMilestonesUnlocked(String soldierId, Set<String> ids) {
    final current = state.milestonesOf(soldierId);
    if (ids.every(current.contains)) return Future.value();

    return _persist(
      state.copyWith(
        unlockedMilestones: {
          ...state.unlockedMilestones,
          soldierId: {...current, ...ids},
        },
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
