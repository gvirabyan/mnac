import 'dart:async';

import 'package:depitun/core/di/providers.dart';
import 'package:depitun/core/l10n/app_language.dart';
import 'package:depitun/domain/entities/announcement.dart';
import 'package:depitun/domain/entities/app_settings.dart';
import 'package:depitun/domain/repositories/announcements_repository.dart';
import 'package:depitun/presentation/announcements/announcements_screen.dart';
import 'package:depitun/presentation/shared/state/announcements_provider.dart';
import 'package:depitun/services/push_arrivals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRepo implements AnnouncementsRepository {
  final recent = StreamController<List<Announcement>>.broadcast();
  final latest = StreamController<Announcement?>.broadcast();

  @override
  Stream<List<Announcement>> watchRecent({int limit = 50}) => recent.stream;

  @override
  Stream<Announcement?> watchLatest() => latest.stream;
}

class _FakePush implements PushArrivals {
  final Set<String> arrived = {};
  final controller = StreamController<String>.broadcast();
  Set<String> tray = {};

  @override
  Set<String> get arrivedIds => arrived;

  @override
  Stream<String> get arrivals => controller.stream;

  @override
  Future<Set<String>> deliveredKeys() async => tray;

  void arrive(String id) {
    arrived.add(id);
    controller.add(id);
  }
}

Announcement _a(String id, DateTime at) =>
    Announcement(
      id: id,
      texts: {AppLanguage.hy: AnnouncementText(title: 'T$id', body: 'B$id')},
      sentAt: at,
    );

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  // "Now" is 21:05; a1 went out yesterday, a2 two minutes ago.
  final t0 = DateTime(2026, 10, 9, 21, 5);
  final a1 = _a('1', DateTime(2026, 10, 8, 22, 43));
  final a2 = _a('2', DateTime(2026, 10, 9, 21, 3));

  late _FakeRepo repo;
  late _FakePush push;
  late DateTime clock;
  late ProviderContainer c;

  Future<void> start(
    Map<String, Object> prefsValues, {
    Set<String> arrivedBefore = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    repo = _FakeRepo();
    push = _FakePush()..arrived.addAll(arrivedBefore);
    clock = t0;
    c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialSettingsProvider.overrideWithValue(AppSettings.defaults),
        initialActiveIdProvider.overrideWithValue(null),
        announcementsRepositoryProvider.overrideWithValue(repo),
        pushArrivalsProvider.overrideWithValue(push),
        announcementClockProvider.overrideWithValue(() => clock),
      ],
    );
    addTearDown(c.dispose);
    c.listen(hasUnreadAnnouncementsProvider, (_, _) {});
    c.listen(announcementsProvider, (_, _) {});
    await _settle();
  }

  bool dot() => c.read(hasUnreadAnnouncementsProvider);

  List<String>? visibleIds() {
    final list = c.read(announcementsProvider).value;
    if (list == null) return null;
    return c
        .read(announcementGateProvider)
        .visible(list)
        .map((a) => a.id)
        .toList();
  }

  Future<void> publish(List<Announcement> newestFirst) async {
    repo.latest.add(newestFirst.first);
    repo.recent.add(newestFirst);
    await _settle();
  }

  final seenA1 = {'announcements_seen_v1': a1.sentAt.millisecondsSinceEpoch};

  group('bell dot', () {
    test('no dot while there are no announcements', () async {
      await start({});
      repo.latest.add(null);
      await _settle();
      expect(dot(), isFalse);
    });

    test('shows for an unseen announcement, clears once seen', () async {
      await start({});
      await publish([a1]);
      expect(dot(), isTrue);

      await c.read(announcementsSeenProvider.notifier).markSeen(a1.sentAt);
      expect(dot(), isFalse);
    });

    test('seen time persists and never moves backwards', () async {
      await start({'announcements_seen_v1': a2.sentAt.millisecondsSinceEpoch});
      expect(c.read(announcementsSeenProvider), a2.sentAt);
      await c.read(announcementsSeenProvider.notifier).markSeen(a1.sentAt);
      expect(c.read(announcementsSeenProvider), a2.sentAt);
    });
  });

  group('waits for the push', () {
    test('a fresh one stays hidden until its push arrives', () async {
      await start(seenA1);
      await publish([a2, a1]);
      expect(dot(), isFalse);
      expect(visibleIds(), ['1']);

      push.arrive('2');
      await _settle();
      expect(dot(), isTrue);
      expect(visibleIds(), ['2', '1']);
    });

    test('also when the app opens while the push is still on its way',
        () async {
      // What slipped through before: the app opened just after the send.
      await start(seenA1);
      await publish([a2, a1]);
      await c.read(announcementGateProvider.notifier).refresh();
      expect(visibleIds(), ['1']);
      expect(dot(), isFalse);
    });

    test('a push that came while the app was away is found in the tray',
        () async {
      await start(seenA1);
      await publish([a2, a1]);
      push.tray = {deliveryKey('T2', 'B2')};
      await c.read(announcementGateProvider.notifier).refresh();
      expect(visibleIds(), ['2', '1']);
      expect(dot(), isTrue);
    });

    test('a push that opened the app counts as arrived', () async {
      await start(seenA1, arrivedBefore: {'2'});
      await publish([a2, a1]);
      expect(visibleIds(), ['2', '1']);
    });

    test('old ones never wait', () async {
      await start({});
      await publish([a1]);
      expect(visibleIds(), ['1']);
    });

    test('shows anyway once the backstop passes without a push', () async {
      await start(seenA1);
      await publish([a2, a1]);
      expect(visibleIds(), ['1']);

      clock = a2.sentAt.add(announcementPushGrace);
      await c.read(announcementGateProvider.notifier).refresh();
      expect(visibleIds(), ['2', '1']);
      expect(dot(), isTrue);
    });
  });

  group('screen', () {
    Future<(ProviderContainer, _FakeRepo, SharedPreferences)> pump(
      WidgetTester tester,
      Map<String, Object> prefsValues,
    ) async {
      SharedPreferences.setMockInitialValues(prefsValues);
      final prefs = await SharedPreferences.getInstance();
      final repo = _FakeRepo();
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            initialSettingsProvider.overrideWithValue(AppSettings.defaults),
            initialActiveIdProvider.overrideWithValue(null),
            announcementsRepositoryProvider.overrideWithValue(repo),
            announcementClockProvider.overrideWithValue(() => t0),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(home: AnnouncementsScreen());
            },
          ),
        ),
      );
      return (container, repo, prefs);
    }

    final old = _a('0', DateTime(2026, 10, 7, 9));

    testWidgets('lists announcements and marks them seen', (tester) async {
      final (container, repo, prefs) = await pump(tester, {
        'announcements_seen_v1': old.sentAt.millisecondsSinceEpoch,
      });
      repo.recent.add([a1, old]);
      await tester.pump();
      await tester.pump();

      expect(find.text('T1'), findsOneWidget);
      expect(find.text('B0'), findsOneWidget);
      expect(container.read(announcementsSeenProvider), a1.sentAt);
      expect(
        prefs.getInt('announcements_seen_v1'),
        a1.sentAt.millisecondsSinceEpoch,
      );
    });

    testWidgets('leaves out one still waiting for its push', (tester) async {
      final (_, repo, _) = await pump(tester, {});
      repo.recent.add([a2, a1]);
      await tester.pump();
      await tester.pump();
      expect(find.text('T2'), findsNothing);
      expect(find.text('T1'), findsOneWidget);
    });

    testWidgets('shows the empty state', (tester) async {
      final (_, repo, _) = await pump(tester, {});
      repo.recent.add(const []);
      await tester.pump();
      await tester.pump();
      expect(find.text('Ծանուցումներ դեռ չկան'), findsOneWidget);
    });
  });
}
