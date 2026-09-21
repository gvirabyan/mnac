import 'package:depitun/core/di/providers.dart';
import 'package:depitun/domain/entities/app_settings.dart';
import 'package:depitun/domain/entities/soldier_profile.dart';
import 'package:depitun/presentation/milestones/milestones_controller.dart';
import 'package:depitun/presentation/shared/state/settings_controller.dart';
import 'package:depitun/presentation/shared/state/soldiers_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pendingCelebration reports the new milestone, then clears once marked',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final profile = SoldierProfile(
      id: 'p1',
      serviceStart: DateTime.now().subtract(const Duration(days: 365)),
      serviceDurationDays: 730, // ~50%
      createdAt: DateTime.now(),
    );

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialSoldiersProvider.overrideWithValue([profile]),
        initialActiveIdProvider.overrideWithValue(profile.id),
        initialSettingsProvider.overrideWithValue(AppSettings.defaults),
      ],
    );
    addTearDown(container.dispose);

    // Keep the autoDispose provider alive for the test.
    final sub = container.listen(pendingCelebrationProvider, (_, _) {});
    addTearDown(sub.close);

    // Half way through a two-year term: the 50% milestone falls on the same
    // day as "one year served" and wins the tie as the headline entry.
    expect(container.read(pendingCelebrationProvider)?.id, 'pct50');

    await container
        .read(settingsControllerProvider.notifier)
        .markMilestonesUnlocked(
          profile.id,
          container
              .read(milestonesProvider)
              .where((m) => m.unlocked)
              .map((m) => m.id)
              .toSet(),
        );

    expect(container.read(pendingCelebrationProvider), isNull);
  });

  test('milestones celebrated by one soldier leave another one untouched',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final start = DateTime.now().subtract(const Duration(days: 365));
    final first = SoldierProfile(
      id: 'p1',
      serviceStart: start,
      serviceDurationDays: 730, // ~50%
      createdAt: DateTime.now(),
    );
    final second = SoldierProfile(
      id: 'p2',
      serviceStart: start,
      serviceDurationDays: 730,
      createdAt: DateTime.now(),
    );

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialSoldiersProvider.overrideWithValue([first, second]),
        initialActiveIdProvider.overrideWithValue(first.id),
        initialSettingsProvider.overrideWithValue(AppSettings.defaults),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(pendingCelebrationProvider, (_, _) {});
    addTearDown(sub.close);

    await container
        .read(settingsControllerProvider.notifier)
        .markMilestonesUnlocked(
          first.id,
          container
              .read(milestonesProvider)
              .where((m) => m.unlocked)
              .map((m) => m.id)
              .toSet(),
        );
    expect(container.read(pendingCelebrationProvider), isNull);

    // The second profile has earned the same milestones on its own and has
    // celebrated none of them.
    await container.read(soldiersControllerProvider.notifier).setActive(
          second.id,
        );
    expect(container.read(pendingCelebrationProvider)?.id, 'pct50');
  });

  test('an app-wide unlocked set is handed to the soldier active on load',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final profile = SoldierProfile(
      id: 'p1',
      serviceStart: DateTime.now().subtract(const Duration(days: 365)),
      serviceDurationDays: 730,
      createdAt: DateTime.now(),
    );

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialSoldiersProvider.overrideWithValue([profile]),
        initialActiveIdProvider.overrideWithValue(profile.id),
        initialSettingsProvider.overrideWithValue(
          const AppSettings(
            unlockedMilestones: {
              AppSettings.legacyMilestonesKey: {'pct25', 'pct50'},
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final settings = container.read(settingsControllerProvider);
    expect(settings.milestonesOf(profile.id), {'pct25', 'pct50'});
    expect(
      settings.unlockedMilestones.containsKey(AppSettings.legacyMilestonesKey),
      isFalse,
    );
  });
}
