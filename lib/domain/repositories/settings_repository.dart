import '../entities/app_settings.dart';

/// Persistence contract for user settings. Implemented in the data layer.
abstract interface class SettingsRepository {
  /// Loads stored settings, falling back to [AppSettings.defaults].
  Future<AppSettings> load();

  /// Persists the given settings.
  Future<void> save(AppSettings settings);

  /// Restores settings to defaults.
  Future<void> clear();
}
