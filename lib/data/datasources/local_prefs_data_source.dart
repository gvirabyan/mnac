import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper over [SharedPreferences] that owns the app's storage keys.
///
/// All persistence is local; values are stored as JSON strings.
class LocalPrefsDataSource {
  LocalPrefsDataSource(this._prefs);

  final SharedPreferences _prefs;

  /// Legacy single-profile key (pre multi-soldier); kept for migration.
  static const String profileKey = 'profile_v1';
  static const String soldiersKey = 'soldiers_v1';
  static const String activeSoldierKey = 'active_soldier_v1';
  static const String settingsKey = 'settings_v1';

  // Legacy single profile (migration source only).
  String? readProfileJson() => _prefs.getString(profileKey);
  Future<void> deleteProfile() => _prefs.remove(profileKey);

  // Soldiers list.
  String? readSoldiersJson() => _prefs.getString(soldiersKey);

  Future<void> writeSoldiersJson(String json) =>
      _prefs.setString(soldiersKey, json);

  Future<void> deleteSoldiers() => _prefs.remove(soldiersKey);

  // Active soldier id.
  String? readActiveSoldierId() => _prefs.getString(activeSoldierKey);

  Future<void> writeActiveSoldierId(String id) =>
      _prefs.setString(activeSoldierKey, id);

  Future<void> deleteActiveSoldierId() => _prefs.remove(activeSoldierKey);

  String? readSettingsJson() => _prefs.getString(settingsKey);

  Future<void> writeSettingsJson(String json) =>
      _prefs.setString(settingsKey, json);

  Future<void> deleteSettings() => _prefs.remove(settingsKey);
}
