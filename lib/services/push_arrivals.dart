/// Which announcement pushes have reached this device — what the push
/// history waits on before showing an announcement. Implemented by
/// `PushService`.
abstract interface class PushArrivals {
  /// Ids of announcements whose push reached the app this run: received
  /// while it was open, or tapped to open it.
  Set<String> get arrivedIds;

  /// The same ids, as they arrive.
  Stream<String> get arrivals;

  /// [deliveryKey]s of the notifications now in the system tray, which holds
  /// pushes that arrived while the app was in the background or closed.
  Future<Set<String>> deliveredKeys();
}

/// Identifies a notification by its text: what the tray reports, and all an
/// announcement and its push have in common.
String deliveryKey(String title, String body) => '$title\n$body';
