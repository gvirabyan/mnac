import 'dart:convert';

import '../../domain/entities/soldier_profile.dart';
import '../../domain/repositories/soldiers_repository.dart';
import '../datasources/local_prefs_data_source.dart';
import '../models/soldier_profile_model.dart';

/// SharedPreferences-backed implementation of [SoldiersRepository].
///
/// Stores the soldiers list as a JSON array. On first load it transparently
/// migrates a legacy single `profile_v1` record into the new list.
class SoldiersRepositoryImpl implements SoldiersRepository {
  SoldiersRepositoryImpl(this._dataSource);

  final LocalPrefsDataSource _dataSource;

  @override
  Future<List<SoldierProfile>> loadAll() async {
    final raw = _dataSource.readSoldiersJson();
    if (raw != null) {
      return _decodeList(raw);
    }

    // Migration: wrap a legacy single profile into the new list.
    final legacy = _dataSource.readProfileJson();
    if (legacy != null) {
      try {
        final profile = SoldierProfileModel.fromJson(
          jsonDecode(legacy) as Map<String, dynamic>,
        ).toEntity();
        await saveAll([profile]);
        await saveActiveId(profile.id);
        await _dataSource.deleteProfile();
        return [profile];
      } catch (_) {
        return const [];
      }
    }
    return const [];
  }

  @override
  Future<void> saveAll(List<SoldierProfile> soldiers) {
    final list = soldiers
        .map((s) => SoldierProfileModel.fromEntity(s).toJson())
        .toList(growable: false);
    return _dataSource.writeSoldiersJson(jsonEncode(list));
  }

  @override
  Future<String?> loadActiveId() async => _dataSource.readActiveSoldierId();

  @override
  Future<void> saveActiveId(String? id) {
    if (id == null) return _dataSource.deleteActiveSoldierId();
    return _dataSource.writeActiveSoldierId(id);
  }

  @override
  Future<void> clear() async {
    await _dataSource.deleteSoldiers();
    await _dataSource.deleteActiveSoldierId();
  }

  List<SoldierProfile> _decodeList(String raw) {
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) =>
              SoldierProfileModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
