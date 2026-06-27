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

  test('pendingCelebration reports the new threshold, then clears once marked',
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

    expect(container.read(pendingCelebrationProvider), 50);

    await container
        .read(settingsControllerProvider.notifier)
        .markMilestonesUnlocked({25, 50});

    expect(container.read(pendingCelebrationProvider), isNull);
  });
}
