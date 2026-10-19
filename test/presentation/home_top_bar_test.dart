import 'package:depitun/core/di/providers.dart';
import 'package:depitun/domain/entities/announcement.dart';
import 'package:depitun/domain/entities/app_settings.dart';
import 'package:depitun/domain/entities/soldier_profile.dart';
import 'package:depitun/domain/repositories/announcements_repository.dart';
import 'package:depitun/presentation/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoAnnouncements implements AnnouncementsRepository {
  @override
  Stream<List<Announcement>> watchRecent({int limit = 50}) =>
      Stream.value(const []);

  @override
  Stream<Announcement?> watchLatest() => Stream.value(null);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<double> shareIconSize(WidgetTester tester, String name) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final profile = SoldierProfile(
      id: 'p1',
      name: name,
      serviceStart: DateTime.now().subtract(const Duration(days: 100)),
      serviceDurationDays: 548,
      createdAt: DateTime.now(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          initialSettingsProvider.overrideWithValue(AppSettings.defaults),
          initialSoldiersProvider.overrideWithValue([profile]),
          initialActiveIdProvider.overrideWithValue(profile.id),
          announcementsRepositoryProvider.overrideWithValue(_NoAnnouncements()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    final size = tester.getSize(find.byIcon(Icons.send_rounded)).width;
    // Unmount, then run out the pending timers — the quote of the day waits
    // for the next midnight, so skip a full day of fake time.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(days: 1, seconds: 2));
    return size;
  }

  testWidgets('short name keeps regular icons', (tester) async {
    expect(await shareIconSize(tester, 'Ան'), 24);
  });

  testWidgets('long name switches icons to compact', (tester) async {
    expect(await shareIconSize(tester, 'Ալեքսանդր Մկրտչյան'), 22);
  });
}
