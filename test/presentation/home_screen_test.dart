import 'package:depitun/app/app.dart';
import 'package:depitun/core/di/providers.dart';
import 'package:depitun/domain/entities/app_settings.dart';
import 'package:depitun/domain/entities/soldier_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        ],
        child: const DepiTunApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // The "until home" label appears in the ring.
    expect(find.text('Մինչև տուն'), findsWidgets);
    // The glass nav bar is present with the home tab selected.
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);

    // Let pending timers settle to avoid test teardown warnings.
    await tester.pump(const Duration(seconds: 1));
  });
}
