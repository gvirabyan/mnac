import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../domain/entities/announcement.dart';
import '../../../domain/repositories/announcements_repository.dart';

/// Ids of announcements whose push just reached the open app. Overridden in
/// `main` with `PushService.announcementArrivals`; empty in tests.
final announcementArrivalsProvider = Provider<Stream<String>>(
  (ref) => const Stream.empty(),
);

/// What the push gate knows in this session; see [AnnouncementGate].
class AnnouncementGateState {
  const AnnouncementGateState({
    this.hasBaseline = false,
    this.watermark,
    this.cachedLatest,
    this.arrived = const {},
    this.live = const {},
  });

  /// Whether the server has confirmed what existed when the app came to the
  /// foreground. Until then nothing is held back.
  final bool hasBaseline;

  /// Send time of the newest announcement at the baseline; null when there
  /// was none. Anything sent after it was sent while the app was open.
  final DateTime? watermark;

  /// Newest send time from the device cache, used before the baseline.
  final DateTime? cachedLatest;

  /// Announcements whose push has reached this device.
  final Set<String> arrived;

  /// Announcements seen arriving after the baseline, with their send times.
  final Map<String, DateTime> live;

  /// Whether [a] was sent while the app was open and its push has not yet
  /// reached this device.
  bool holds(Announcement a) =>
      hasBaseline &&
      (watermark == null || a.sentAt.isAfter(watermark!)) &&
      !arrived.contains(a.id);

  /// [list] minus what is being held back.
  List<Announcement> visible(List<Announcement> list) =>
      [for (final a in list) if (!holds(a)) a];

  /// Send time of the newest announcement the app may show.
  DateTime? get latestVisible {
    if (!hasBaseline) return cachedLatest;
    var latest = watermark;
    for (final MapEntry(key: id, value: sentAt) in live.entries) {
      if (!arrived.contains(id)) continue;
      if (latest == null || sentAt.isAfter(latest)) latest = sentAt;
    }
    return latest;
  }
}

/// Keeps an announcement out of the app until its push is on screen.
///
/// The history is read straight from Firestore, which learns of a new
/// announcement within a second or two; the push itself fans out to every
/// device and can take minutes to land. Shown as-is, the bell would light up
/// before the banner appears.
///
/// The gap only shows while the app is open — otherwise nobody sees the bell
/// — and in the open app the push arrives in code (see
/// `PushService.announcementArrivals`). So an announcement sent while the app
/// is open is held back until that push arrives, and released in the same
/// moment its banner is shown.
///
/// What was sent before the app came to the foreground is never held: the
/// push had its chance while the user was away. That line is drawn from the
/// server's own send times — the newest one the server confirms when the app
/// starts or returns from the background — never from the device clock,
/// which may be wrong. Returning from the background redraws it, which also
/// releases anything still held (on a device whose notifications are off,
/// for instance, its push would never arrive).
class AnnouncementGate extends Notifier<AnnouncementGateState> {
  late AnnouncementsRepository _repository;
  StreamSubscription<LatestAnnouncement>? _latest;

  @override
  AnnouncementGateState build() {
    _repository = ref.watch(announcementsRepositoryProvider);
    final arrivals = ref.watch(announcementArrivalsProvider).listen(_onArrival);
    final lifecycle = AppLifecycleListener(onRestart: _rebaseline);
    ref.onDispose(() {
      arrivals.cancel();
      lifecycle.dispose();
      _latest?.cancel();
    });
    _listenLatest();
    return const AnnouncementGateState();
  }

  void _listenLatest() {
    _latest?.cancel();
    _latest = _repository.watchLatest().listen(_onLatest);
  }

  /// Starts over from a fresh server-confirmed baseline. Re-listening is what
  /// guarantees one: a listener that survived the background would not
  /// report anything until the data changed.
  void _rebaseline() {
    state = AnnouncementGateState(arrived: state.arrived);
    _listenLatest();
  }

  void _onLatest(LatestAnnouncement event) {
    final latest = event.announcement;
    final current = state;
    if (!current.hasBaseline) {
      state = AnnouncementGateState(
        hasBaseline: event.isConfirmed,
        watermark: event.isConfirmed ? latest?.sentAt : null,
        cachedLatest: latest?.sentAt,
        arrived: current.arrived,
      );
      return;
    }
    // Recorded even when its push already arrived — the push can beat
    // Firestore — so the bell still learns its send time.
    if (latest == null) return;
    final watermark = current.watermark;
    if (watermark != null && !latest.sentAt.isAfter(watermark)) return;
    state = AnnouncementGateState(
      hasBaseline: true,
      watermark: current.watermark,
      cachedLatest: current.cachedLatest,
      arrived: current.arrived,
      live: {...current.live, latest.id: latest.sentAt},
    );
  }

  void _onArrival(String id) {
    final current = state;
    state = AnnouncementGateState(
      hasBaseline: current.hasBaseline,
      watermark: current.watermark,
      cachedLatest: current.cachedLatest,
      arrived: {...current.arrived, id},
      live: current.live,
    );
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
  final latest = ref.watch(announcementGateProvider).latestVisible;
  if (latest == null) return false;
  final seen = ref.watch(announcementsSeenProvider);
  return seen == null || latest.isAfter(seen);
});
