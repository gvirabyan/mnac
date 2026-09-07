import 'dart:async' show unawaited;
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_service.dart';

/// Firebase Cloud Messaging: receives broadcasts sent to every user.
///
/// Everyone is subscribed to a single [broadcastTopic], so a message published
/// to that topic — from the Firebase console or the FCM API — reaches the whole
/// install base without the app ever uploading device tokens anywhere.
///
/// The OS draws the notification itself while the app is backgrounded or shut;
/// a message that lands with the app open is handed to Dart instead, and is
/// re-shown through [NotificationService] so it isn't silently swallowed.
class PushService {
  PushService(this._notifications, [FirebaseMessaging? messaging])
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final NotificationService _notifications;
  final FirebaseMessaging _messaging;

  /// Native side of [diagnostics] on iOS: what the app delegate saw APNs do,
  /// which Dart is never told about.
  static const MethodChannel _iosDiagnostics =
      MethodChannel('com.virabyan.mnac/push_diagnostics');

  /// The topic every install subscribes to. Sending to it is how a message
  /// reaches all users; keep it in step with what the console targets.
  static const String broadcastTopic = 'all';

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
  }

  /// Joins [broadcastTopic].
  ///
  /// iOS cannot subscribe before APNs has handed Firebase a device token, so
  /// this waits for one rather than giving up on the first look — see
  /// [_awaitApnsToken]. Android has no such step and subscribes straight away.
  Future<void> _subscribeToBroadcasts() async {
    if (Platform.isIOS && !await _awaitApnsToken()) return;
    await _messaging.subscribeToTopic(broadcastTopic);
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
        final native = await _iosDiagnostics.invokeMethod<String>('report');
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

    try {
      await _messaging.subscribeToTopic(broadcastTopic);
      lines.add('topic $broadcastTopic: subscribed');
    } catch (e) {
      lines.add('topic $broadcastTopic: FAILED ($e)');
    }

    return lines.join('\n');
  }

  /// Joins the topic, swallowing any failure.
  ///
  /// Also worth calling after the user grants notification permission: on iOS
  /// that is what finally lets APNs issue a token, so an attempt made earlier
  /// may have timed out.
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
