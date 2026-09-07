import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
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

  /// The topic every install subscribes to. Sending to it is how a message
  /// reaches all users; keep it in step with what the console targets.
  static const String broadcastTopic = 'all';

  Future<void> init() async {
    try {
      FirebaseMessaging.onMessage.listen(_showForegroundMessage);
      await _subscribeToBroadcasts();
    } catch (_) {
      // Push is an extra, never a reason for startup to fail.
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
  /// iOS cannot subscribe before APNs has handed Firebase a device token, and
  /// that only arrives once the user has allowed notifications — so a refusal
  /// here is normal and simply means this device stays unsubscribed until a
  /// later launch. [ensureSubscribed] is what picks it up again.
  Future<void> _subscribeToBroadcasts() async {
    if (Platform.isIOS && await _messaging.getAPNSToken() == null) return;
    await _messaging.subscribeToTopic(broadcastTopic);
  }

  /// Re-attempts the subscription. Call after the user grants notification
  /// permission, since on iOS the first attempt at launch will have been
  /// skipped for want of an APNs token.
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
