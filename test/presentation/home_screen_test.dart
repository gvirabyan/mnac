import 'package:depitun/core/di/providers.dart';
import 'package:depitun/domain/entities/app_settings.dart';
import 'package:depitun/domain/entities/announcement.dart';
import 'package:depitun/domain/entities/soldier_profile.dart';
import 'package:depitun/domain/repositories/announcements_repository.dart';
import 'package:depitun/presentation/shell/main_shell.dart';
import 'package:depitun/services/interstitial_ad_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The home bell reads Firestore; tests run without Firebase.
class _NoAnnouncements implements AnnouncementsRepository {
  @override
  Stream<List<Announcement>> watchRecent({int limit = 50}) =>
      Stream.value(const []);

  @override
  Stream<Announcement?> watchLatest() => Stream.value(null);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('shows live countdown for an existing profile', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final profile = SoldierProfile(
      id: 'p1',
      serviceStart: DateTime.now().subtract(const Duration(days: 365)),
      serviceDurationDays: 730,
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
          // Holds no ad, so the launch check just bumps a counter.
          interstitialAdServiceProvider.overrideWithValue(
            InterstitialAdService(prefs),
          ),
        ],
        // The shell directly: the full app opens on the splash, whose
        // hand-off starts the consent prompts, ad SDK and push setup that
        // need real platform plugins.
        child: const MaterialApp(home: MainShell()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // The "until home" label appears in the ring.
    expect(find.text('Մինչև տուն'), findsWidgets);
    // The glass nav bar is present with the home tab selected.
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);

    // Unmount, then run out the pending timers — the quote of the day waits
    // for the next midnight, so skip a full day of fake time.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(days: 1, seconds: 2));
  });
}
