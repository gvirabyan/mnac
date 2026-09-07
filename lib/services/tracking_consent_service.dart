import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';

/// iOS App Tracking Transparency gate.
///
/// AdMob (and the Unity mediation adapter behind it) may only read the IDFA
/// after the user has answered the system prompt, so this runs *before*
/// `MobileAds.instance.initialize()`. Denied or restricted is not an error
/// path: the SDK simply falls back to non-personalised ads.
class TrackingConsentService {
  const TrackingConsentService();

  /// Shows the ATT prompt once per install and resolves with the final status.
  ///
  /// On Android — and on iOS versions without ATT — there is nothing to ask,
  /// so this reports [TrackingStatus.notSupported] without touching the
  /// platform channel.
  Future<TrackingStatus> request() async {
    if (!Platform.isIOS) return TrackingStatus.notSupported;

    try {
      var status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // The prompt is dropped silently unless the app is already active;
        // at cold start the first frame has not landed yet, so give UIKit a
        // moment to finish presenting before asking.
        await Future<void>.delayed(const Duration(milliseconds: 400));
        // Bounded because startup waits on this: on iOS 17.4+ a request made
        // while the app is inactive is answered by the plugin only once the
        // app becomes active again, so an unlucky launch could otherwise hold
        // the splash screen indefinitely.
        status = await AppTrackingTransparency.requestTrackingAuthorization()
            .timeout(
              const Duration(seconds: 20),
              onTimeout: () => TrackingStatus.notDetermined,
            );
      }
      return status;
    } catch (_) {
      // A missing plugin or a channel error must never block startup.
      return TrackingStatus.notSupported;
    }
  }
}
