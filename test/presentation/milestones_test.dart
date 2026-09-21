import 'package:depitun/core/di/providers.dart';
import 'package:depitun/domain/entities/app_settings.dart';
import 'package:depitun/domain/entities/soldier_profile.dart';
import 'package:depitun/presentation/milestones/milestones_controller.dart';
import 'package:depitun/presentation/shared/state/settings_controller.dart';
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
          container
              .read(milestonesProvider)
              .where((m) => m.unlocked)
              .map((m) => m.id)
              .toSet(),
        );

    expect(container.read(pendingCelebrationProvider), isNull);
  });
}
