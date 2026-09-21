import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/l10n/app_strings.dart';
import '../domain/entities/app_settings.dart';
import '../domain/entities/soldier_profile.dart';
import '../domain/usecases/compute_milestones.dart';
import '../domain/usecases/compute_service_progress.dart';

/// Schedules local, offline notifications:
///
/// * A daily "inactivity" reminder at the chosen time (default 19:00): a batch
///   of one-shot notifications for the next [_dailyDays] days is scheduled, and
///   re-topped on every app open. Because we re-schedule from *tomorrow* on each
///   open (cancelling the whole range first), today's reminder is cancelled the
///   moment the user opens the app — so it only fires on days the app was not
///   opened by the reminder time.
/// * Milestone notifications, pre-scheduled at each upcoming milestone date.
///
/// All scheduling is inexact (no exact-alarm permission) and best-effort: any
/// platform error is swallowed so the UI is never affected.
class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const String _channelId = 'depitun_reminders';
  static const String _channelName = 'Հիշեցումներ';
  static const String _channelDesc = 'Մնաց հիշեցումներ';

  static const int _dailyBase = 1000;
  static const int _dailyWindow = 60; // reserved id range to cancel
  static const int _dailyDays = 30; // how many days ahead to schedule
  static const int _milestoneBase = 2000;
  static const int _pushBase = 3000;
  static const int _pushWindow = 100;
  static const int _milestoneWindow = 20;

  /// Native side of [openSystemSettings].
  static const MethodChannel _settingsChannel =
      MethodChannel('com.virabyan.mnac/app_settings');

  static const _compute = ComputeServiceProgress();
  static const _computeMilestones = ComputeMilestones();

  Future<void> init() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        settings:
            const InitializationSettings(android: androidInit, iOS: iosInit),
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.high,
        ),
      );
      _initialized = true;
    } catch (_) {
      // Notifications unavailable (e.g. in tests) — keep the app working.
    }
  }

  /// Whether the OS currently lets the app post notifications.
  ///
  /// Asked of the system rather than remembered, because the answer can change
  /// behind the app's back at any time: the user can revoke — or grant —
  /// notifications from the system settings while the app sits in the
  /// background. An unknown answer counts as granted, so a platform that
  /// cannot report (or a test double) never silently disables reminders.
  Future<bool> hasPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.areNotificationsEnabled() ?? true;
      }

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final options = await ios.checkPermissions();
        return options?.isEnabled ?? true;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Opens the app's notification settings in the OS.
  ///
  /// The escape hatch for a refused permission: the system prompt is a
  /// one-time offer (twice on Android, once on iOS), after which a request
  /// returns false without showing anything, and the only way back is the
  /// settings app. Returns false if the screen could not be opened.
  Future<bool> openSystemSettings() async {
    try {
      return await _settingsChannel
              .invokeMethod<bool>('openNotificationSettings') ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Requests OS notification permission. Returns true if granted (or unknown).
  ///
  /// Only ever shows a dialog while the OS still has one to show; once the
  /// permission is permanently denied this returns false immediately, which is
  /// the caller's cue to send the user to [openSystemSettings].
  Future<bool> requestPermissions() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final androidGranted =
          await android?.requestNotificationsPermission() ?? true;

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final iosGranted = await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          true;

      return androidGranted && iosGranted;
    } catch (_) {
      return false;
    }
  }

  /// Re-schedules all notifications for the active soldier according to
  /// [settings]. Call on app start, on resume, and whenever the active soldier
  /// or notification settings change.
  Future<void> sync({
    required SoldierProfile? soldier,
    required AppSettings settings,
    required List<String> quotes,
  }) async {
    try {
      await _cancelRange(_dailyBase, _dailyWindow);
      await _cancelRange(_milestoneBase, _milestoneWindow);

      if (!settings.notificationsEnabled || soldier == null) return;

      if (settings.dailyReminderEnabled) {
        await _scheduleDaily(soldier, settings, quotes);
      }
      if (settings.milestoneNotificationsEnabled) {
        await _scheduleMilestones(soldier);
      }
    } catch (_) {
      // Best-effort.
    }
  }

  Future<void> _scheduleDaily(
    SoldierProfile soldier,
    AppSettings settings,
    List<String> quotes,
  ) async {
    final now = tz.TZDateTime.now(tz.local);
    final hour = settings.dailyReminderMinutes ~/ 60;
    final minute = settings.dailyReminderMinutes % 60;

    // Start from tomorrow: the user just opened the app, so today is satisfied.
    for (var offset = 1; offset <= _dailyDays; offset++) {
      final day = now.add(Duration(days: offset));
      final when =
          tz.TZDateTime(tz.local, day.year, day.month, day.day, hour, minute);
      if (!when.isAfter(now)) continue;

      final progress = _compute(
        soldier,
        DateTime(day.year, day.month, day.day, hour, minute),
      );
      if (progress.isComplete) continue;

      final quote = quotes.isEmpty ? '' : quotes[offset % quotes.length];
      final body = quote.isEmpty
          ? AppStrings.daysLeftBody(progress.daysRemaining)
          : '${AppStrings.daysLeftBody(progress.daysRemaining)} · $quote';

      await _plugin.zonedSchedule(
        id: _dailyBase + offset,
        title: AppStrings.appName,
        body: body,
        scheduledDate: when,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> _scheduleMilestones(SoldierProfile soldier) async {
    final now = tz.TZDateTime.now(tz.local);
    final progress = _compute(soldier, DateTime.now());
    final milestones = _computeMilestones(progress);

    var idx = 0;
    for (final m in milestones) {
      if (m.unlocked || idx >= _milestoneWindow) continue;
      final d = m.estimatedDate;
      final when = tz.TZDateTime(tz.local, d.year, d.month, d.day, 12, 0);
      if (!when.isAfter(now)) continue;

      await _plugin.zonedSchedule(
        id: _milestoneBase + idx,
        title: AppStrings.milestoneReached,
        body: '${AppStrings.milestoneTitle(m.id)} · '
            '${AppStrings.milestoneMessage(m.id)}',
        scheduledDate: when,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      idx++;
    }
  }

  /// Shows [title]/[body] immediately, on the reminders channel.
  ///
  /// Used for pushes that land while the app is in the foreground: FCM hands
  /// those to the app instead of drawing them itself, so without this a
  /// broadcast is silently swallowed by anyone who happens to have the app
  /// open. The id sits in its own range so it can never collide with a
  /// scheduled reminder or milestone.
  Future<void> showNow({required String title, required String body}) async {
    if (!_initialized) await init();
    try {
      await _plugin.show(
        id: _pushBase + DateTime.now().millisecondsSinceEpoch % _pushWindow,
        title: title,
        body: body,
        notificationDetails: _details,
      );
    } catch (_) {
      // Best-effort.
    }
  }

  Future<void> _cancelRange(int base, int count) async {
    for (var i = 0; i < count; i++) {
      await _plugin.cancel(id: base + i);
    }
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        // Present alert/sound even while the app is in the foreground (iOS does
        // not show a banner for in-app notifications unless asked to).
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          presentBanner: true,
          presentList: true,
        ),
      );
}

/// Marks that the user asked for notifications, was found to be blocked by the
/// OS, and was sent to the system settings to lift it.
///
/// The trip out to the settings app is the one case where a granted permission
/// must switch the app's own toggle back on by itself: the user already asked
/// for it here, and coming back to a switch still sitting at "off" would read
/// as the settings change having been ignored. Without the flag, a resume
/// could not tell that case apart from someone who simply has notifications
/// allowed and deliberately keeps the app's reminders off.
const String notificationsPendingEnableKey = 'notifications_pending_enable';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);
