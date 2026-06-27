import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../domain/entities/soldier_profile.dart';

/// Immutable state holding all soldiers and the active selection.
class SoldiersState {
  const SoldiersState({required this.soldiers, required this.activeId});

  final List<SoldierProfile> soldiers;
  final String? activeId;

  SoldiersState copyWith({
    List<SoldierProfile>? soldiers,
    String? activeId,
    bool clearActive = false,
  }) {
    return SoldiersState(
      soldiers: soldiers ?? this.soldiers,
      activeId: clearActive ? null : (activeId ?? this.activeId),
    );
  }
}

/// Manages the list of soldiers and which one is active. Seeded synchronously
/// from [initialSoldiersProvider] / [initialActiveIdProvider].
class SoldiersController extends Notifier<SoldiersState> {
  @override
  SoldiersState build() {
    final soldiers = ref.watch(initialSoldiersProvider);
    final stored = ref.watch(initialActiveIdProvider);
    final activeId = _resolveActive(soldiers, stored);
    return SoldiersState(soldiers: soldiers, activeId: activeId);
  }

  /// Picks a valid active id: the stored one if still present, else the first.
  static String? _resolveActive(List<SoldierProfile> soldiers, String? stored) {
    if (soldiers.isEmpty) return null;
    if (stored != null && soldiers.any((s) => s.id == stored)) return stored;
    return soldiers.first.id;
  }

  Future<void> _persist(SoldiersState next) async {
    state = next;
    final repo = ref.read(soldiersRepositoryProvider);
    await repo.saveAll(next.soldiers);
    await repo.saveActiveId(next.activeId);
  }

  /// Adds a new soldier (making it active) or updates an existing one by id.
  Future<void> addOrUpdate(SoldierProfile profile) {
    final existingIndex =
        state.soldiers.indexWhere((s) => s.id == profile.id);
    final soldiers = [...state.soldiers];
    if (existingIndex >= 0) {
      soldiers[existingIndex] = profile;
      return _persist(state.copyWith(soldiers: soldiers));
    }
    soldiers.add(profile);
    return _persist(state.copyWith(soldiers: soldiers, activeId: profile.id));
  }

  /// Sets the active soldier.
  Future<void> setActive(String id) =>
      _persist(state.copyWith(activeId: id));

  /// Deletes a soldier; if it was active, falls back to the first remaining.
  Future<void> delete(String id) {
    final soldiers = state.soldiers.where((s) => s.id != id).toList();
    final activeId = state.activeId == id
        ? (soldiers.isEmpty ? null : soldiers.first.id)
        : state.activeId;
    return _persist(SoldiersState(soldiers: soldiers, activeId: activeId));
  }

  /// Re-reads from storage (used after a restore).
  Future<void> reload() async {
    final repo = ref.read(soldiersRepositoryProvider);
    final soldiers = await repo.loadAll();
    final stored = await repo.loadActiveId();
    state = SoldiersState(
      soldiers: soldiers,
      activeId: _resolveActive(soldiers, stored),
    );
  }

  /// Removes everything (used by the app reset flow).
  Future<void> clearAll() async {
    await ref.read(soldiersRepositoryProvider).clear();
    state = const SoldiersState(soldiers: [], activeId: null);
  }
}

final soldiersControllerProvider =
    NotifierProvider<SoldiersController, SoldiersState>(SoldiersController.new);

/// The currently active soldier, or null when none exist.
final activeSoldierProvider = Provider<SoldierProfile?>((ref) {
  final s = ref.watch(soldiersControllerProvider);
  if (s.soldiers.isEmpty) return null;
  return s.soldiers.firstWhere(
    (x) => x.id == s.activeId,
    orElse: () => s.soldiers.first,
  );
});
