import 'dart:convert';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/local_prefs_data_source.dart';
import '../models/app_settings_model.dart';

/// SharedPreferences-backed implementation of [SettingsRepository].
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._dataSource);

  final LocalPrefsDataSource _dataSource;

  @override
  Future<AppSettings> load() async {
    final raw = _dataSource.readSettingsJson();
    if (raw == null) return AppSettings.defaults;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AppSettingsModel.fromJson(map).settings;
    } catch (_) {
      return AppSettings.defaults;
    }
  }

  @override
  Future<void> save(AppSettings settings) {
    final json = jsonEncode(AppSettingsModel(settings).toJson());
    return _dataSource.writeSettingsJson(json);
  }

  @override
  Future<void> clear() => _dataSource.deleteSettings();
}
