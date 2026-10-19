import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../domain/entities/announcement.dart';
import '../../../services/push_arrivals.dart';
import 'settings_controller.dart';

/// How long after sending an announcement shows even though its push was
/// never seen on this device — when notifications are off, say, or it was
/// swiped away unseen. Only a backstop: normally the push itself releases it.
const announcementPushGrace = Duration(minutes: 10);

/// Pushes that reached this device. Overridden in `main` with the
/// `PushService`; in tests, nothing ever arrives.
final pushArrivalsProvider = Provider<PushArrivals>((ref) => const _NoArrivals());

class _NoArrivals implements PushArrivals {
  const _NoArrivals();

  @override
  Set<String> get arrivedIds => const {};

  @override
  Stream<String> get arrivals => const Stream.empty();

  @override
  Future<Set<String>> deliveredKeys() async => const {};
}

/// The clock the gate reads; overridden in tests.
final announcementClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// What the push gate knows; see [AnnouncementGate].
class AnnouncementGateState {
  const AnnouncementGateState({
    required this.now,
    this.arrived = const {},
    this.inTray = const {},
    this.latest,
    this.shownLatest,
  });

  /// When this state was worked out.
  final DateTime now;

  /// Announcements whose push reached the app while it ran.
  final Set<String> arrived;

  /// [deliveryKey]s of notifications in the system tray when last looked.
  final Set<String> inTray;

  /// The newest sent announcement, as the server reports it.
  final Announcement? latest;

  /// Send time of the newest announcement shown so far this run — what the
  /// bell goes by while [latest] is still held back.
  final DateTime? shownLatest;

  /// Whether [a] stays out of the app: it has no text in the app's language,
  /// or its push has not been seen on this device and it is too fresh to
  /// show without it.
  bool holds(Announcement a) {
    final text = a.textIn(AppStrings.language);
    if (text == null) return true;
    return !arrived.contains(a.id) &&
        !inTray.contains(deliveryKey(text.title, text.body)) &&
        now.isBefore(a.sentAt.add(announcementPushGrace));
  }

  /// [list] minus what is being held back.
  List<Announcement> visible(List<Announcement> list) =>
      [for (final a in list) if (!holds(a)) a];

  /// Send time of the newest announcement the app may show.
  DateTime? get latestVisible {
    final latest = this.latest;
    if (latest != null && !holds(latest)) return latest.sentAt;
    return shownLatest;
  }

  AnnouncementGateState copyWith({
    DateTime? now,
    Set<String>? arrived,
    Set<String>? inTray,
    Announcement? latest,
  }) {
    final next = AnnouncementGateState(
      now: now ?? this.now,
      arrived: arrived ?? this.arrived,
      inTray: inTray ?? this.inTray,
      latest: latest ?? this.latest,
      shownLatest: shownLatest,
    );
    // Remember the newest one ever shown, for the bell to fall back on.
    final visible = next.latestVisible;
    if (visible == null || visible == shownLatest) return next;
    return AnnouncementGateState(
      now: next.now,
      arrived: next.arrived,
      inTray: next.inTray,
      latest: next.latest,
      shownLatest: visible,
    );
  }
}

/// Keeps an announcement out of the app until its push is on this phone.
///
/// The history is read straight from Firestore, which hears of a new
/// announcement within a second or two; the push itself fans out to every
/// device and can take minutes to land. Shown as-is, the bell would light up
/// before the banner appears.
///
/// So a freshly sent announcement waits for its own push, seen any of three
/// ways: it arrives while the app is open, it is tapped to open the app, or
/// it is sitting in the system tray (checked at launch and on every return
/// to the app). Only if none of that happens — notifications off, the
/// banner swiped away unseen — does it show anyway, [announcementPushGrace]
/// after it was sent.
class AnnouncementGate extends Notifier<AnnouncementGateState> {
  late PushArrivals _push;
  late DateTime Function() _clock;
  Timer? _backstop;

  @override
  AnnouncementGateState build() {
    _push = ref.watch(pushArrivalsProvider);
    _clock = ref.watch(announcementClockProvider);
    final repository = ref.watch(announcementsRepositoryProvider);

    final latest = repository.watchLatest().listen(
      (a) => _update((s) => s.copyWith(latest: a)),
    );
    final arrivals = _push.arrivals.listen(
      (id) => _update((s) => s.copyWith(arrived: {...s.arrived, id})),
    );
    final lifecycle = AppLifecycleListener(onResume: refresh);
    ref.onDispose(() {
      latest.cancel();
      arrivals.cancel();
      lifecycle.dispose();
      _backstop?.cancel();
    });

    unawaited(Future.microtask(refresh));
    return AnnouncementGateState(now: _clock(), arrived: _push.arrivedIds);
  }

  /// Looks at the tray and the clock again. Runs at launch, on every return
  /// to the app, and when a held announcement's backstop comes due.
  Future<void> refresh() async {
    final inTray = await _push.deliveredKeys();
    if (!ref.mounted) return;
    _update(
      (s) => s.copyWith(
        inTray: inTray,
        arrived: {...s.arrived, ..._push.arrivedIds},
      ),
    );
  }

  void _update(AnnouncementGateState Function(AnnouncementGateState) change) {
    state = change(state).copyWith(now: _clock());
    _scheduleBackstop();
  }

  /// Wakes up when the newest announcement, if held, may show without its
  /// push.
  void _scheduleBackstop() {
    _backstop?.cancel();
    final latest = state.latest;
    if (latest == null || !state.holds(latest)) return;
    final due = latest.sentAt.add(announcementPushGrace).difference(state.now);
    _backstop = Timer(due + const Duration(seconds: 1), refresh);
  }
}

final announcementGateProvider =
    NotifierProvider<AnnouncementGate, AnnouncementGateState>(
      AnnouncementGate.new,
    );

/// The push history, newest first, unfiltered — pass it through
/// [AnnouncementGateState.visible] before showing it.
///
/// Reads up to 50 documents each time it is first watched, so only the
/// history screen should watch it — the home bell goes through
/// [hasUnreadAnnouncementsProvider], which reads one.
final announcementsProvider = StreamProvider.autoDispose<List<Announcement>>(
  (ref) => ref.watch(announcementsRepositoryProvider).watchRecent(),
);

/// Send time of the newest announcement the user has already seen in the
/// history screen; null if they have never opened it. Stored locally.
class AnnouncementsSeenController extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    final ms = ref.watch(localPrefsDataSourceProvider).readAnnouncementsSeenAt();
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Records [sentAt] as seen. Never moves backwards, so opening a stale
  /// cached list cannot resurrect the unread marker.
  Future<void> markSeen(DateTime sentAt) async {
    final current = state;
    if (current != null && !sentAt.isAfter(current)) return;
    state = sentAt;
    await ref
        .read(localPrefsDataSourceProvider)
        .writeAnnouncementsSeenAt(sentAt.millisecondsSinceEpoch);
  }
}

final announcementsSeenProvider =
    NotifierProvider<AnnouncementsSeenController, DateTime?>(
      AnnouncementsSeenController.new,
    );

/// Whether the home bell should carry its "new" dot: there is a visible
/// announcement newer than the last one seen.
final hasUnreadAnnouncementsProvider = Provider<bool>((ref) {
  // What is visible depends on the language, which the gate reads directly.
  ref.watch(settingsControllerProvider.select((s) => s.language));
  final latest = ref.watch(announcementGateProvider).latestVisible;
  if (latest == null) return false;
  final seen = ref.watch(announcementsSeenProvider);
  return seen == null || latest.isAfter(seen);
});
