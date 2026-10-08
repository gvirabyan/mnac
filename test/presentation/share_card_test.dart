import 'package:depitun/core/constants/app_assets.dart';
import 'package:depitun/domain/entities/soldier_profile.dart';
import 'package:depitun/domain/usecases/compute_service_progress.dart';
import 'package:depitun/presentation/share/share_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('without a photo the card uses the default background',
      (tester) async {
    // Room for the card's full 360x640.
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // The test font draws every glyph as a wide square, so the card's text
    // overflows here though it fits on a device; only the background is
    // under test.
    final onError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      onError?.call(details);
    };
    addTearDown(() => FlutterError.onError = onError);

    final profile = SoldierProfile(
      id: 'p1',
      serviceStart: DateTime.now().subtract(const Duration(days: 100)),
      serviceDurationDays: 548,
      createdAt: DateTime.now(),
    );
    final progress = const ComputeServiceProgress()(profile, DateTime.now());

    await tester.pumpWidget(
      MaterialApp(
        home: Center(child: ShareCard(profile: profile, progress: progress)),
      ),
    );

    final backgrounds = tester
        .widgetList<Image>(find.byType(Image))
        .map((i) => i.image)
        .whereType<AssetImage>()
        .where((a) => a.assetName == AppAssets.defaultBackground);
    expect(backgrounds, hasLength(1));
  });
}
