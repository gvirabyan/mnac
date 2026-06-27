import 'package:depitun/core/di/providers.dart';
import 'package:depitun/domain/entities/soldier_profile.dart';
import 'package:depitun/presentation/shared/state/soldiers_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SoldierProfile soldier(String id) => SoldierProfile(
        id: id,
        name: 'Soldier $id',
        serviceStart: DateTime(2025, 1, 1),
        serviceDurationDays: 730,
        createdAt: DateTime(2025, 1, 1),
      );

  Future<ProviderContainer> makeContainer() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialSoldiersProvider.overrideWithValue(const []),
        initialActiveIdProvider.overrideWithValue(null),
      ],
    );
  }

  test('adding soldiers makes the newest active and persists', () async {
    final container = await makeContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(soldiersControllerProvider.notifier);

    await ctrl.addOrUpdate(soldier('a'));
    expect(container.read(activeSoldierProvider)?.id, 'a');

    await ctrl.addOrUpdate(soldier('b'));
    final state = container.read(soldiersControllerProvider);
    expect(state.soldiers.length, 2);
    expect(container.read(activeSoldierProvider)?.id, 'b');

    final persisted =
        await container.read(soldiersRepositoryProvider).loadAll();
    expect(persisted.map((s) => s.id), containsAll(['a', 'b']));
  });

  test('switching and deleting the active soldier falls back correctly',
      () async {
    final container = await makeContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(soldiersControllerProvider.notifier);

    await ctrl.addOrUpdate(soldier('a'));
    await ctrl.addOrUpdate(soldier('b'));

    await ctrl.setActive('a');
    expect(container.read(activeSoldierProvider)?.id, 'a');

    await ctrl.delete('a');
    expect(container.read(activeSoldierProvider)?.id, 'b');
    expect(container.read(soldiersControllerProvider).soldiers.length, 1);
  });

  test('editing an existing soldier keeps the active selection', () async {
    final container = await makeContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(soldiersControllerProvider.notifier);

    await ctrl.addOrUpdate(soldier('a'));
    await ctrl.addOrUpdate(soldier('b')); // active = b
    await ctrl.addOrUpdate(soldier('a').copyWith(name: 'Renamed'));

    expect(container.read(activeSoldierProvider)?.id, 'b');
    final a = container
        .read(soldiersControllerProvider)
        .soldiers
        .firstWhere((s) => s.id == 'a');
    expect(a.name, 'Renamed');
  });
}
