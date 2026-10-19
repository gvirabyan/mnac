// ignore_for_file: invalid_use_of_visible_for_testing_member, depend_on_referenced_packages
// Renders the store listing images from the real app, once per language
// (<lang> is hy, ru or en):
//
//   store/app_store/<lang>/iphone_6_3/NN_<scene>.png  1206x2622  (required)
//   store/app_store/<lang>/ipad_13/NN_<scene>.png     2064x2752  (required:
//                                                     the app runs on iPad)
//   store/google_play/<lang>/phone/NN_<scene>.png     1080x1920
//   store/google_play/<lang>/feature_graphic.png      1024x500   (required)
//
// Each scene is a real screen with sample soldiers, in the app's dark theme,
// framed in a device on the app's own dark-and-apricot palette under a
// caption.
//
// Run:  python tool/fetch_store_fonts.py      (once: the app's fonts)
//       flutter test tool/store_screenshots_test.dart
//       python tool/flatten_store_images.py   (drops alpha, checks sizes,
//                                              writes the 512px Play icon)
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:depitun/core/di/providers.dart';
import 'package:depitun/core/l10n/app_language.dart';
import 'package:depitun/core/l10n/app_strings.dart';
import 'package:depitun/core/theme/app_colors.dart';
import 'package:depitun/domain/entities/announcement.dart';
import 'package:depitun/domain/entities/app_settings.dart';
import 'package:depitun/domain/entities/soldier_profile.dart';
import 'package:depitun/domain/repositories/announcements_repository.dart';
import 'package:depitun/domain/usecases/compute_service_progress.dart';
import 'package:depitun/presentation/announcements/announcements_screen.dart';
import 'package:depitun/presentation/calendar/calendar_screen.dart';
import 'package:depitun/presentation/home/home_controller.dart';
import 'package:depitun/presentation/home/home_screen.dart';
import 'package:depitun/presentation/milestones/milestones_screen.dart';
import 'package:depitun/presentation/settings/settings_screen.dart';
import 'package:depitun/presentation/share/share_card_screen.dart';
import 'package:depitun/presentation/shared/state/announcements_provider.dart';
import 'package:depitun/presentation/shared/state/theme_providers.dart';
import 'package:depitun/presentation/shell/glass_nav_bar.dart';
import 'package:depitun/presentation/statistics/statistics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One store slot: output folder, the canvas (logical px), its pixel ratio,
/// the device the app is rendered on, and whether that device is a tablet.
typedef Display = ({
  String folder,
  Size canvas,
  double dpr,
  Size device,
  bool tablet,
});

const List<Display> displays = [
  (
    folder: 'app_store/iphone_6_3',
    canvas: Size(402, 874),
    dpr: 3,
    device: Size(402, 874),
    tablet: false,
  ),
  (
    folder: 'app_store/ipad_13',
    canvas: Size(1032, 1376),
    dpr: 2,
    device: Size(1032, 1376),
    tablet: true,
  ),
  (
    folder: 'google_play/phone',
    canvas: Size(360, 640),
    dpr: 3,
    device: Size(393, 852),
    tablet: false,
  ),
];

/// [hy], [ru] or [en], whichever [AppStrings.language] is.
String t(String hy, String ru, String en) => switch (AppStrings.language) {
  AppLanguage.hy => hy,
  AppLanguage.ru => ru,
  AppLanguage.en => en,
};

/// Where [display]'s images go for the current language, e.g.
/// `google_play/ru/phone`.
String folderFor(Display display) {
  final [store, slot] = display.folder.split('/');
  return '$store/${AppStrings.language.id}/$slot';
}

/// Scenes in store order: file name and caption.
List<(String, String)> get scenes => [
  ('home', t('Հաշվիր օրերը\nմինչև տուն', 'Считай дни\nдо дома',
      'Count the days\nuntil home')),
  ('stats', t('Ծառայությունը՝\nմեկ հայացքով', 'Вся служба —\nодним взглядом',
      'Your service\nat a glance')),
  ('milestones', t('Նվաճումներ\nամեն փուլում', 'Достижения\nна каждом этапе',
      'Milestones\nat every stage')),
  ('calendar', t('Կարևոր օրերը՝\nօրացույցում', 'Важные дни —\nв календаре',
      'Key dates\nin a calendar')),
  ('share', t('Կիսվիր\nընկերների հետ', 'Делись\nс друзьями',
      'Share it\nwith friends')),
  ('soldiers', t('Մի քանի զինվոր՝\nմեկ հավելվածում',
      'Все твои солдаты —\nв одном месте', 'Several soldiers,\none app')),
  ('messages', t('Ջերմ խոսքեր\nամեն օր', 'Тёплые слова\nкаждый день',
      'Warm words\nevery day')),
  // The one scene that says the theme can change; every shot is dark.
  ('settings', t('Մուգ կամ բաց՝\nընտրիր թեման', 'Тёмная или светлая —\nвыбирай',
      'Dark or light —\nyour choice')),
];

const _captionFont = 'NotoSerifArmenian_800';
const _kickerFont = 'NotoSansArmenian_700';
// Plain Noto for the Cyrillic and Latin the Armenian faces lack.
const _captionFallback = ['NotoSerif_800'];
const _kickerFallback = ['NotoSans_700'];

/// Loads the app's fonts under the names google_fonts asks for (fetched by
/// tool/fetch_store_fonts.py) plus the Material icons.
Future<void> loadFonts() async {
  final dir = Directory('tool/.cache/fonts');
  if (!dir.existsSync()) {
    throw StateError('Run python tool/fetch_store_fonts.py first.');
  }
  Future<void> load(String family, String path) async {
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
    await loader.load();
  }

  for (final file in dir.listSync().whereType<File>()) {
    final name = file.uri.pathSegments.last.replaceAll('.ttf', '');
    await load(name, file.path);
    // The bare family is what google_fonts lists as the fallback.
    if (name.endsWith('_regular')) {
      await load(name.replaceAll('_regular', ''), file.path);
    }
  }
  await load(
    'MaterialIcons',
    'C:/flutter/src/flutter/bin/cache/artifacts/material_fonts/'
        'materialicons-regular.otf',
  );
}

/// Sample data: three soldiers, a few months to a year in.
final now = DateTime.now();
SoldierProfile get aram => SoldierProfile(
  id: 'aram',
  name: t('Արամ', 'Арам', 'Aram'),
  serviceStart: now.subtract(const Duration(days: 341)),
  serviceDurationDays: 548,
  createdAt: now,
);
SoldierProfile get davit => SoldierProfile(
  id: 'davit',
  name: t('Դավիթ', 'Давид', 'Davit'),
  serviceStart: now.subtract(const Duration(days: 128)),
  serviceDurationDays: 730,
  createdAt: now,
);
SoldierProfile get gor => SoldierProfile(
  id: 'gor',
  name: t('Գոռ', 'Гор', 'Gor'),
  serviceStart: now.subtract(const Duration(days: 467)),
  serviceDurationDays: 548,
  createdAt: now,
);

Announcement _message(String id, int daysAgo, int hour, String title, String body) {
  final day = DateTime(now.year, now.month, now.day - daysAgo, hour, 0);
  return Announcement(
    id: id,
    texts: {AppStrings.language: AnnouncementText(title: title, body: body)},
    sentAt: day,
  );
}

List<Announcement> get messages => [
  _message('1', 0, 22, t('Բարի գիշեր', 'Спокойной ночи', 'Good night'), t(
      'Նրանք արթուն են մնում, որպեսզի մենք հանգիստ քուն ունենանք։',
      'Они не спят, чтобы мы могли спать спокойно.',
      'They stay awake so that we can sleep in peace.')),
  _message('2', 1, 9, t('Բարի լույս', 'Доброе утро', 'Good morning'), t(
      'Եվս մեկ օր դեպի տուն։ Ուժ և համբերություն բոլոր տղաներին։',
      'Ещё один день ближе к дому. Сил и терпения всем ребятам.',
      'One more day closer to home. Strength and patience to all the boys.')),
  _message('3', 3, 20, t('Կարոտը կանցնի', 'Тоска пройдёт', 'The longing will pass'), t(
      'Ամեն անցած օր մոտեցնում է հանդիպումը։ Դուք մենակ չեք։',
      'Каждый прожитый день приближает встречу. Вы не одни.',
      'Every day that passes brings the reunion closer. You are not alone.')),
  _message('4', 6, 12, t('Նոր հնարավորություն', 'Новая возможность', 'Something new'), t(
      'Այժմ կարող եք կիսվել ձեր նվաճումներով ընկերների հետ։',
      'Теперь можно делиться своими достижениями с друзьями.',
      'You can now share your milestones with friends.')),
];

class _Messages implements AnnouncementsRepository {
  @override
  Stream<List<Announcement>> watchRecent({int limit = 50}) =>
      Stream.value(messages);

  @override
  Stream<Announcement?> watchLatest() => Stream.value(messages.first);
}

/// The app's MaterialApp around [home], themed exactly as the real one.
Widget app(Widget home) => Consumer(
  builder: (context, ref, _) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ref.watch(lightThemeProvider),
    darkTheme: ref.watch(darkThemeProvider),
    themeMode: ref.watch(themeModeProvider),
    locale: AppStrings.language.locale,
    supportedLocales: [for (final l in AppLanguage.values) l.locale],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  ),
);

/// A tab of the main shell with its nav bar, minus the shell's side effects
/// (ads, notification sync, celebration dialogs).
class StoreShell extends StatelessWidget {
  const StoreShell(this.index, {super.key});

  final int index;

  static const _screens = [
    HomeScreen(),
    StatisticsScreen(),
    CalendarScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBody: true,
    body: _screens[index],
    bottomNavigationBar: GlassNavBar(
      currentIndex: index,
      onTap: (_) {},
      items: [
        GlassNavItem(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
          label: AppStrings.navHome,
        ),
        GlassNavItem(
          icon: Icons.insights_outlined,
          selectedIcon: Icons.insights_rounded,
          label: AppStrings.navStats,
        ),
        GlassNavItem(
          icon: Icons.calendar_today_outlined,
          selectedIcon: Icons.calendar_today_rounded,
          label: AppStrings.navCalendar,
        ),
        GlassNavItem(
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings_rounded,
          label: AppStrings.navSettings,
        ),
      ],
    ),
  );
}

Future<ui.Image> capture(WidgetTester tester, GlobalKey key, double dpr) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  late ui.Image image;
  await tester.runAsync(
    () async => image = await boundary.toImage(pixelRatio: dpr),
  );
  return image;
}

/// Decodes every image on screen; widget tests otherwise leave them blank.
Future<void> settleImages(WidgetTester tester) async {
  final images = find.byType(Image);
  if (images.evaluate().isEmpty) return;
  final context = tester.element(images.first);
  final providers = tester
      .widgetList<Image>(images)
      .map((i) => i.image)
      .toList();
  await tester.runAsync(() async {
    for (final p in providers) {
      await precacheImage(p, context);
    }
  });
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> savePng(WidgetTester tester, ui.Image image, String path) =>
    tester.runAsync(() async {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    }).then((_) {});

/// Warm charcoal backdrop with an apricot bloom, shared by every frame.
class Backdrop extends StatelessWidget {
  const Backdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3A2A12), Color(0xFF1E1A14), AppColors.charcoalDeep],
        stops: [0, .5, 1],
      ),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        const Align(
          alignment: Alignment(0, -1.25),
          child: FractionallySizedBox(
            widthFactor: 1.6,
            heightFactor: .55,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x55F2A900), Color(0x00F2A900)],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    ),
  );
}

/// A store screenshot: kicker, caption and the real screen in a device that
/// runs off the bottom edge.
class StoreFrame extends StatelessWidget {
  const StoreFrame({
    super.key,
    required this.display,
    required this.shot,
    required this.caption,
  });

  final Display display;
  final ui.Image shot;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final canvas = display.canvas;
    // Scale everything from the 440-wide iPhone layout.
    final k = canvas.width / 440;
    final tablet = display.tablet;
    final shotWidth = canvas.width * (tablet ? .74 : .76);
    final shotHeight = shotWidth * display.device.height / display.device.width;
    final bezel = (tablet ? 12 : 9) * k * (tablet ? .6 : 1);
    final radius = (tablet ? 36 : 52) * k * (tablet ? .7 : 1);
    final captionSize = (tablet ? 30 : 38) * k * (tablet ? .9 : 1);
    final top = canvas.height * (canvas.height / canvas.width > 1.9 ? .232 : .25);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox.fromSize(
        size: canvas,
        child: Backdrop(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                top: canvas.height * .045,
                left: 24 * k,
                right: 24 * k,
                height: top - canvas.height * .065,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.appName.toUpperCase(),
                      style: TextStyle(
                        fontFamily: _kickerFont,
                        fontFamilyFallback: _kickerFallback,
                        color: AppColors.apricot,
                        fontSize: 13 * k * (tablet ? .8 : 1),
                        letterSpacing: 5 * k,
                      ),
                    ),
                    SizedBox(height: 10 * k * (tablet ? .7 : 1)),
                    // Shrinks a caption too wide for the canvas instead of
                    // letting it wrap onto a third line.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                      caption,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        fontFamily: _captionFont,
                        fontFamilyFallback: _captionFallback,
                        color: AppColors.offWhite,
                        fontSize: captionSize,
                        height: 1.18,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 14,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: top,
                left: (canvas.width - shotWidth) / 2 - bezel,
                child: Container(
                  padding: EdgeInsets.all(bezel),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0907),
                    borderRadius: BorderRadius.circular(radius + bezel),
                    border: Border.all(
                      color: const Color(0x66F2A900),
                      width: 1.5 * k * (tablet ? .6 : 1),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x99000000),
                        blurRadius: 40,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: SizedBox(
                      width: shotWidth,
                      height: shotHeight,
                      child: RawImage(image: shot, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Google Play's 1024x500 banner: name and tagline over the default photo,
/// with two screens leaning in from the right.
class FeatureGraphic extends StatelessWidget {
  const FeatureGraphic({super.key, required this.left, required this.right});

  final ui.Image left;
  final ui.Image right;

  Widget _phone(ui.Image shot, double width) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: const Color(0xFF0A0907),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: const Color(0x66F2A900), width: 1.2),
      boxShadow: const [
        BoxShadow(color: Color(0xAA000000), blurRadius: 30, offset: Offset(0, 14)),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: SizedBox(
        width: width,
        height: width * shot.height / shot.width,
        child: RawImage(image: shot, fit: BoxFit.cover),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: SizedBox(
      width: 1024,
      height: 500,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          const Positioned.fill(
            child: Image(
              image: AssetImage('assets/images/background.jpg'),
              fit: BoxFit.cover,
              alignment: Alignment(0, -.2),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xF214110D),
                    Color(0xD914110D),
                    Color(0x6614110D),
                  ],
                  stops: [0, .45, 1],
                ),
              ),
            ),
          ),
          const Positioned(
            left: -120,
            top: -160,
            width: 620,
            height: 520,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x40F2A900), Color(0x00F2A900)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 64,
            top: 0,
            bottom: 0,
            width: 470,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.appName,
                  style: const TextStyle(
                    fontFamily: _captionFont,
                    fontFamilyFallback: _captionFallback,
                    color: AppColors.apricot,
                    fontSize: 96,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  t('Հաշվիր օրերը մինչև տուն', 'Считай дни до дома',
                      'Count the days until home'),
                  style: const TextStyle(
                    fontFamily: _captionFont,
                    fontFamilyFallback: _captionFallback,
                    color: AppColors.offWhite,
                    fontSize: 34,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  t('Հետհաշվարկ · Նվաճումներ · Օրացույց',
                      'Отсчёт · Достижения · Календарь',
                      'Countdown · Milestones · Calendar'),
                  style: const TextStyle(
                    fontFamily: _kickerFont,
                    fontFamilyFallback: _kickerFallback,
                    color: Color(0xB3F1EADD),
                    fontSize: 17,
                    letterSpacing: .5,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 210,
            top: 70,
            child: Transform.rotate(angle: -.08, child: _phone(right, 190)),
          ),
          Positioned(
            right: 40,
            top: 40,
            child: Transform.rotate(angle: .06, child: _phone(left, 200)),
          ),
        ],
      ),
    ),
  );
}

/// Points google_fonts' on-device font cache at the fonts fetched by
/// tool/fetch_store_fonts.py, so the app's own text styles find them.
class _FontCacheDir extends PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async =>
      Directory('tool/.cache/google_fonts').absolute.path;
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    PathProviderPlatform.instance = _FontCacheDir();
  });

  // Shots of the Play phone run, kept for the feature graphic.
  final playShots = <String, ui.Image>{};

  for (final language in AppLanguage.values) {
  for (final display in displays) {
    testWidgets('store images: ${language.id} ${display.folder}', (tester) async {
      AppStrings.language = language;
      await tester.runAsync(loadFonts);
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({
        // Opened the history once, two messages ago: the bell shows a dot.
        'announcements_seen_v1': messages[2].sentAt.millisecondsSinceEpoch,
      });
      final prefs = await SharedPreferences.getInstance();
      final quotes = (await tester.runAsync(
        () => rootBundle.loadString('assets/quotes/quotes_${language.id}.json'),
      ))!;

      final overrides = [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialSettingsProvider.overrideWithValue(
          AppSettings.defaults.copyWith(
            themeMode: AppThemeMode.dark,
            language: language,
            animationLevel: AnimationLevel.reduced,
            notificationsEnabled: true,
          ),
        ),
        initialSoldiersProvider.overrideWithValue([aram, davit, gor]),
        initialActiveIdProvider.overrideWithValue(aram.id),
        announcementsRepositoryProvider.overrideWithValue(_Messages()),
        // Long past every sample message, so none waits for its push.
        announcementClockProvider.overrideWithValue(
          () => now.add(const Duration(days: 1)),
        ),
        quotesProvider.overrideWith(
          (ref) => (jsonDecode(quotes) as List).cast<String>(),
        ),
      ];

      final key = GlobalKey();
      final shots = <ui.Image>[];
      final progress = const ComputeServiceProgress()(aram, now);

      Future<void> shoot(Widget home) async {
        tester.view.physicalSize = display.device * display.dpr;
        tester.view.devicePixelRatio = display.dpr;
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: ProviderScope(
              key: UniqueKey(),
              overrides: overrides,
              child: app(home),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await settleImages(tester);
        await tester.pump(const Duration(seconds: 2));
      }

      Future<void> snap() async =>
          shots.add(await capture(tester, key, display.dpr));

      await shoot(const StoreShell(0));
      await snap();
      await shoot(const StoreShell(1));
      await snap();
      await shoot(const MilestonesScreen());
      await snap();
      await shoot(const StoreShell(2));
      await snap();
      await shoot(ShareCardScreen(profile: aram, progress: progress));
      await snap();
      await shoot(const StoreShell(0));
      await tester.tap(find.text(aram.name!).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await snap();
      await shoot(const AnnouncementsScreen());
      await snap();
      await shoot(const StoreShell(3));
      await snap();

      // Frame and save.
      tester.view.physicalSize = display.canvas * display.dpr;
      tester.view.devicePixelRatio = display.dpr;
      for (var i = 0; i < shots.length; i++) {
        final (name, caption) = scenes[i];
        final frameKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: frameKey,
            child: StoreFrame(display: display, shot: shots[i], caption: caption),
          ),
        );
        await tester.pump();
        final framed = await capture(tester, frameKey, display.dpr);
        await savePng(
          tester,
          framed,
          'store/${folderFor(display)}/${(i + 1).toString().padLeft(2, '0')}_$name.png',
        );
      }

      if (display.folder == 'google_play/phone') {
        playShots['home'] = shots[0];
        playShots['milestones'] = shots[2];
        tester.view.physicalSize = const Size(1024, 500);
        tester.view.devicePixelRatio = 1;
        final bannerKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: bannerKey,
            child: FeatureGraphic(
              left: playShots['home']!,
              right: playShots['milestones']!,
            ),
          ),
        );
        await settleImages(tester);
        final banner = await capture(tester, bannerKey, 1);
        await savePng(
          tester,
          banner,
          'store/google_play/${language.id}/feature_graphic.png',
        );
      }

      // Unmount, then run out the timers the screens leave behind (the
      // quote of the day waits for midnight).
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(days: 1, seconds: 2));
    });
  }
  }
}
