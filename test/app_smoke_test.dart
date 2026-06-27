import 'package:depitun/app/app.dart';
import 'package:depitun/core/di/providers.dart';
import 'package:depitun/domain/entities/app_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    // Avoid network font fetches during tests; fall back to bundled defaults.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('boots into home empty-state when there is no profile',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          initialSettingsProvider.overrideWithValue(AppSettings.defaults),
          initialSoldiersProvider.overrideWithValue(const []),
          initialActiveIdProvider.overrideWithValue(null),
        ],
        child: const DepiTunApp(),
      ),
    );
    await tester.pump();

    // The home empty-state invites adding a soldier (Armenian).
    expect(find.text('Դեռ տվյալներ չկան'), findsOneWidget);
    expect(find.text('Ավելացնել'), findsOneWidget);
  });
}
