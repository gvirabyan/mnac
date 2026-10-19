import 'dart:async' show StreamController, unawaited;
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_language.dart';
import '../core/l10n/app_strings.dart';
import 'notification_service.dart';
import 'push_arrivals.dart';

/// Firebase Cloud Messaging: receives broadcasts sent to every user.
///
/// Every install is subscribed to the topic of its app language
/// ([topicFor]), so a message published to the three of them — from the FCM
/// API, see `functions/index.js` — reaches the whole install base, each user
/// in their own language, without the app ever uploading device tokens.
///
/// The OS draws the notification itself while the app is backgrounded or shut;
/// a message that lands with the app open is handed to Dart instead, and is
/// re-shown through [NotificationService] so it isn't silently swallowed.
class PushService implements PushArrivals {
  PushService(this._notifications, [FirebaseMessaging? messaging])
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final NotificationService _notifications;
  final FirebaseMessaging _messaging;

  final StreamController<String> _arrivals =
      StreamController<String>.broadcast();
  final Set<String> _arrivedIds = {};

  @override
  Set<String> get arrivedIds => Set.unmodifiable(_arrivedIds);

  @override
  Stream<String> get arrivals => _arrivals.stream;

  @override
  Future<Set<String>> deliveredKeys() async => {
    for (final n in await _notifications.delivered())
      deliveryKey(n.title, n.body),
  };

  /// Notes that the push for an announcement reached this device. The push
  /// history holds a fresh announcement back until then, so it never shows
  /// in the app ahead of its push.
  void _recordArrival(RemoteMessage message) {
    final id = message.data['announcementId'];
    if (id is! String || !_arrivedIds.add(id)) return;
    _arrivals.add(id);
  }

  /// Native side of [diagnostics] on iOS: what the app delegate saw APNs do,
  /// which Dart is never told about.
  static const MethodChannel _iosDiagnostics =
      MethodChannel('com.virabyan.mnac/diagnostics');

  /// The topic app versions from before translated pushes subscribe to; it
  /// carries the Armenian text. Left on joining a language topic, so a phone
  /// never gets the same push twice.
  static const String broadcastTopic = 'all';

  /// The topic for users reading the app in [language], e.g. `all_ru`. Keep
  /// in step with what `functions/index.js` sends to.
  static String topicFor(AppLanguage language) =>
      '${broadcastTopic}_${language.id}';

  /// How long to wait for APNs. Generous because it covers a cold start on
  /// a slow network; nothing is blocked on it, the wait runs in the
  /// background while the app carries on.
  static const Duration _apnsTokenTimeout = Duration(seconds: 20);

  /// Starts listening for pushes that arrive with the app open.
  ///
  /// Joining the topic is deliberately *not* done here: on iOS that path
  /// raises the notification prompt, and the caller decides when that should
  /// happen relative to the other system prompt at startup. Call
  /// [ensureSubscribed] once that ordering is settled.
  void init() {
    try {
      FirebaseMessaging.onMessage.listen(_showForegroundMessage);
      // A tapped push opened the app: it has arrived, whether or not it is
      // still in the tray.
      FirebaseMessaging.onMessageOpenedApp.listen(_recordArrival);
      unawaited(
        _messaging.getInitialMessage().then((m) {
          if (m != null) _recordArrival(m);
        }),
      );
      if (Platform.isIOS) unawaited(_registerWithApns());
    } catch (_) {
      // Push is an extra, never a reason for startup to fail.
    }
  }

  /// Asks iOS to register with APNs, in case the launch path didn't.
  ///
  /// The plugin registers at launch itself, but only if Firebase's auto-init
  /// flag reads as on — and it reads that flag from the *native* Firebase app
  /// while `didFinishLaunching` is still running. What puts a native app
  /// there that early is `ios/Runner/GoogleService-Info.plist`; configuring
  /// Firebase from Dart happens too late to count. Lose that file and the
  /// flag comes back off, registration is skipped, and nothing ever retries:
  /// APNs never calls back, the token stays null, and every topic send is
  /// dropped. Permission does not stand in for this — it is a separate step,
  /// which is why a device in that state reports itself authorized while
  /// still having no token.
  ///
  /// Setting the flag here, once Firebase is up, runs the registration the
  /// launch path would have skipped, so the failure cannot return silently.
  /// Redundant when the plist is in place, and harmless: registering twice
  /// costs nothing. Android talks to FCM directly and needs none of it.
  Future<void> _registerWithApns() async {
    try {
      await _messaging.setAutoInitEnabled(true);
    } catch (_) {
      // Same reasoning as above: never fatal.
    }
  }

  void _showForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    final title = notification.title;
    final body = notification.body;
    if (title == null && body == null) return;
    _notifications.showNow(title: title ?? '', body: body ?? '');
    _recordArrival(message);
  }

  /// Joins the topic of the current app language and leaves every other one,
  /// [broadcastTopic] included.
  ///
  /// iOS cannot subscribe before APNs has handed Firebase a device token, so
  /// this waits for one rather than giving up on the first look — see
  /// [_awaitApnsToken]. Android has no such step and subscribes straight away.
  Future<void> _subscribeToBroadcasts() async {
    if (Platform.isIOS && !await _awaitApnsToken()) return;
    final language = AppStrings.language;
    await _messaging.subscribeToTopic(topicFor(language));
    await _messaging.unsubscribeFromTopic(broadcastTopic);
    for (final other in AppLanguage.values) {
      if (other != language) {
        await _messaging.unsubscribeFromTopic(topicFor(other));
      }
    }
  }

  /// Waits for APNs to issue this device a token, up to [_apnsTokenTimeout].
  ///
  /// Two things have to happen first, and neither is instant. The app must
  /// register with APNs — `requestPermission` is what does that on iOS, and
  /// it raises no second prompt once the user has already answered — and APNs
  /// must then answer over the network. Reading the token once at launch is
  /// therefore almost guaranteed to come back null, which previously left the
  /// device permanently unsubscribed and every broadcast silently missed.
  Future<bool> _awaitApnsToken() async {
    await _messaging.requestPermission();

    final deadline = DateTime.now().add(_apnsTokenTimeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await _messaging.getAPNSToken() != null) return true;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return false;
  }

  /// A readable account of why this device is, or isn't, reachable by push.
  ///
  /// Every step of the chain is silent when it fails, and on iOS none of it is
  /// observable from the outside: a topic send reports success whatever
  /// becomes of the message afterwards. Walking the chain in order tells you
  /// where it breaks — permission, then the APNs token that only Apple can
  /// issue, then the FCM token derived from it, then the topic itself.
  ///
  /// The FCM token is included in full so a message can be aimed at this one
  /// device, which unlike a topic send returns the reason it failed.
  Future<String> diagnostics() async {
    final lines = <String>[];

    try {
      final settings = await _messaging.getNotificationSettings();
      lines.add('permission: ${settings.authorizationStatus.name}');
    } catch (e) {
      lines.add('permission: FAILED ($e)');
    }

    if (Platform.isIOS) {
      try {
        final apns = await _messaging.getAPNSToken();
        lines.add('apns token: ${apns == null ? 'MISSING' : 'present'}');
      } catch (e) {
        lines.add('apns token: FAILED ($e)');
      }
      // Says *why* the token above is missing: whether iOS refused
      // registration outright, and whether the signed build even carries a
      // push entitlement. Without this the report stops at "MISSING", which
      // is true of every cause at once.
      try {
        final native = await _iosDiagnostics.invokeMethod<String>('push');
        if (native != null) lines.add(native);
      } catch (e) {
        lines.add('native diagnostics: FAILED ($e)');
      }
    }

    try {
      final fcm = await _messaging.getToken();
      lines.add('fcm token: ${fcm ?? 'MISSING'}');
    } catch (e) {
      lines.add('fcm token: FAILED ($e)');
    }

    final topic = topicFor(AppStrings.language);
    try {
      await _messaging.subscribeToTopic(topic);
      lines.add('topic $topic: subscribed');
    } catch (e) {
      lines.add('topic $topic: FAILED ($e)');
    }

    return lines.join('\n');
  }

  /// Joins the topic, swallowing any failure.
  ///
  /// Also worth calling after the user grants notification permission: on iOS
  /// that is what finally lets APNs issue a token, so an attempt made earlier
  /// may have timed out. And after a language switch, which moves the user to
  /// another topic.
  Future<void> ensureSubscribed() async {
    try {
      await _subscribeToBroadcasts();
    } catch (_) {
      // Best-effort; the next launch tries again.
    }
  }
}

final pushServiceProvider = Provider<PushService>(
  (ref) => throw UnimplementedError('pushServiceProvider must be overridden'),
);
