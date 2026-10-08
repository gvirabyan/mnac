import 'dart:async';

import 'package:depitun/core/di/providers.dart';
import 'package:depitun/domain/entities/announcement.dart';
import 'package:depitun/domain/repositories/announcements_repository.dart';
import 'package:depitun/presentation/announcements/announcements_screen.dart';
import 'package:depitun/presentation/shared/state/announcements_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRepo implements AnnouncementsRepository {
  final recent = StreamController<List<Announcement>>.broadcast();
  final latest = StreamController<LatestAnnouncement>.broadcast();
  int latestListens = 0;

  @override
  Stream<List<Announcement>> watchRecent({int limit = 50}) => recent.stream;

  @override
  Stream<LatestAnnouncement> watchLatest() {
    latestListens++;
    return latest.stream;
  }

  void server(Announcement? a) =>
      latest.add(LatestAnnouncement(a, isConfirmed: true));

  void cache(Announcement? a) =>
      latest.add(LatestAnnouncement(a, isConfirmed: false));
}

Announcement _a(String id, DateTime at) =>
    Announcement(id: id, title: 'T$id', body: 'B$id', sentAt: at);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final t1 = DateTime(2026, 10, 1, 10);
  final t2 = DateTime(2026, 10, 2, 10);
  final a1 = _a('1', t1);
  final a2 = _a('2', t2);

  late _FakeRepo repo;
  late StreamController<String> arrivals;
  late ProviderContainer c;

  Future<void> start([Map<String, Object> prefsValues = const {}]) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    repo = _FakeRepo();
    arrivals = StreamController<String>.broadcast();
    c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        announcementsRepositoryProvider.overrideWithValue(repo),
        announcementArrivalsProvider.overrideWithValue(arrivals.stream),
      ],
    );
    addTearDown(c.dispose);
    c.listen(hasUnreadAnnouncementsProvider, (_, _) {});
    c.listen(announcementsProvider, (_, _) {});
    await _settle();
  }

  List<String>? visibleIds() => c
      .read(announcementsProvider)
      .value
      ?.where((a) => !c.read(announcementGateProvider).holds(a))
      .map((a) => a.id)
      .toList();

  group('bell dot', () {
    test('no dot while there are no announcements', () async {
      await start();
      repo.server(null);
      await _settle();
      expect(c.read(hasUnreadAnnouncementsProvider), isFalse);
    });

    test('shows for an unseen announcement, clears once seen', () async {
      await start();
      repo.server(a1);
      await _settle();
      expect(c.read(hasUnreadAnnouncementsProvider), isTrue);

      await c.read(announcementsSeenProvider.notifier).markSeen(t1);
      expect(c.read(hasUnreadAnnouncementsProvider), isFalse);
    });

    test('seen time persists and never moves backwards', () async {
      await start({'announcements_seen_v1': t2.millisecondsSinceEpoch});
      expect(c.read(announcementsSeenProvider), t2);
      await c.read(announcementsSeenProvider.notifier).markSeen(t1);
      expect(c.read(announcementsSeenProvider), t2);
    });
  });

  group('gate', () {
    test('sent while the app is open: hidden until its push arrives',
        () async {
      await start({'announcements_seen_v1': t1.millisecondsSinceEpoch});
      repo.server(a1);
      repo.recent.add([a1]);
      await _settle();
      expect(c.read(hasUnreadAnnouncementsProvider), isFalse);

      // Firestore learns of it first: still nothing in the app.
      repo.server(a2);
      repo.recent.add([a2, a1]);
      await _settle();
      expect(c.read(hasUnreadAnnouncementsProvider), isFalse);
      expect(visibleIds(), ['1']);

      // The push lands: dot and list update together.
      arrivals.add('2');
      await _settle();
      expect(c.read(hasUnreadAnnouncementsProvider), isTrue);
      expect(visibleIds(), ['2', '1']);
    });

    test('push arriving before Firestore shows it straight away', () async {
      await start({'announcements_seen_v1': t1.millisecondsSinceEpoch});
      repo.server(a1);
      await _settle();

      arrivals.add('2');
      await _settle();
      repo.server(a2);
      repo.recent.add([a2, a1]);
      await _settle();
      expect(c.read(hasUnreadAnnouncementsProvider), isTrue);
      expect(visibleIds(), ['2', '1']);
    });

    test('sent while the app was closed is never held', () async {
      await start({'announcements_seen_v1': t1.millisecondsSinceEpoch});
      // Stale cache first, then the server reports the newer one.
      repo.cache(a1);
      await _settle();
      repo.server(a2);
      repo.recent.add([a2, a1]);
      await _settle();
      expect(c.read(hasUnreadAnnouncementsProvider), isTrue);
      expect(visibleIds(), ['2', '1']);
    });

    test('returning from the background releases what is held', () async {
      await start({'announcements_seen_v1': t1.millisecondsSinceEpoch});
      repo.server(a1);
      await _settle();
      repo.server(a2);
      repo.recent.add([a2, a1]);
      await _settle();
      expect(visibleIds(), ['1']);
      final listensBefore = repo.latestListens;

      // Background and back, one legal step at a time.
      final binding = TestWidgetsFlutterBinding.instance;
      for (final state in const [
        AppLifecycleState.resumed,
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        binding.handleAppLifecycleStateChanged(state);
      }
      await _settle();

      // Listens afresh and nothing is held until a new baseline exists.
      expect(repo.latestListens, listensBefore + 1);
      expect(visibleIds(), ['2', '1']);
      repo.server(a2);
      await _settle();
      expect(visibleIds(), ['2', '1']);
      expect(c.read(hasUnreadAnnouncementsProvider), isTrue);
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
            announcementsRepositoryProvider.overrideWithValue(repo),
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

    testWidgets('lists announcements and marks them seen', (tester) async {
      final (container, repo, prefs) = await pump(tester, {
        'announcements_seen_v1': t1.millisecondsSinceEpoch,
      });
      repo.recent.add([a2, a1]);
      await tester.pump();
      await tester.pump();

      expect(find.text('T2'), findsOneWidget);
      expect(find.text('B1'), findsOneWidget);
      expect(container.read(announcementsSeenProvider), t2);
      expect(prefs.getInt('announcements_seen_v1'), t2.millisecondsSinceEpoch);
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
