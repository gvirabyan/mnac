import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/repositories/backup_repository.dart';
import '../datasources/local_prefs_data_source.dart';

/// Implements local backup/restore by serializing the stored profile and
/// settings JSON into a single file in the app documents directory.
class BackupRepositoryImpl implements BackupRepository {
  BackupRepositoryImpl(this._dataSource);

  final LocalPrefsDataSource _dataSource;

  static const String _fileName = 'depitun_backup.json';
  static const int _schemaVersion = 1;

  @override
  Future<String> exportJson() async {
    final soldiersRaw = _dataSource.readSoldiersJson();
    final settingsRaw = _dataSource.readSettingsJson();
    return jsonEncode({
      'version': _schemaVersion,
      'soldiers': soldiersRaw == null ? null : jsonDecode(soldiersRaw),
      'activeId': _dataSource.readActiveSoldierId(),
      'settings': settingsRaw == null ? null : jsonDecode(settingsRaw),
    });
  }

  @override
  Future<void> importJson(String json) async {
    final map = jsonDecode(json) as Map<String, dynamic>;
    final soldiers = map['soldiers'];
    final activeId = map['activeId'];
    final settings = map['settings'];
    if (soldiers != null) {
      await _dataSource.writeSoldiersJson(jsonEncode(soldiers));
    }
    if (activeId is String) {
      await _dataSource.writeActiveSoldierId(activeId);
    }
    if (settings != null) {
      await _dataSource.writeSettingsJson(jsonEncode(settings));
    }
  }

  @override
  Future<String> writeBackupFile() async {
    final file = await _backupFile();
    await file.writeAsString(await exportJson());
    return file.path;
  }

  @override
  Future<String?> readBackupFile() async {
    final file = await _backupFile();
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  Future<File> _backupFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }
}
