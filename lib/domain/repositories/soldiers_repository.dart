import '../entities/soldier_profile.dart';

/// Persistence contract for the list of soldiers and the active selection.
abstract interface class SoldiersRepository {
  /// Loads all soldiers (migrating a legacy single profile if present).
  Future<List<SoldierProfile>> loadAll();

  /// Saves the full soldiers list.
  Future<void> saveAll(List<SoldierProfile> soldiers);

  /// Loads the active soldier id, or null.
  Future<String?> loadActiveId();

  /// Persists the active soldier id (null clears it).
  Future<void> saveActiveId(String? id);

  /// Removes all soldiers and the active selection.
  Future<void> clear();
}
