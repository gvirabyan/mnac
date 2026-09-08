import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:gma_mediation_unity/gma_mediation_unity.dart';

/// Propagates the App Tracking Transparency answer to every SDK that would
/// otherwise track on its own.
///
/// This has to run *before* `MobileAds.instance.initialize()`: the Unity
/// adapter starts the Unity Ads SDK from inside that call, and Unity reads its
/// consent metadata once, at startup.
///
/// Setting the flags explicitly — in both directions — is what suppresses
/// Unity's own "Can the Unity cookie collect and use your data" dialog. Left
/// unset, Unity treats consent as unknown and asks the user itself, which App
/// Review reads as collecting data for tracking after the user declined
/// (guideline 5.1.1(iv)).
class AdConsentService {
  const AdConsentService();

  /// [personalised] mirrors ATT: true only when tracking was authorised.
  Future<void> apply({required bool personalised}) async {
    // Unity Ads, via the AdMob mediation adapter. `gdpr.consent` covers the
    // EU prompt, `privacy.consent` the rest of the world; Unity shows its
    // dialog unless both are known.
    try {
      final unity = GmaMediationUnity();
      await unity.setGDPRConsent(personalised);
      await unity.setCCPAConsent(personalised);
    } catch (_) {
      // A missing adapter must never block startup.
    }

    // Firebase Analytics links the IDFA whenever the ad SDK pulls AdSupport in,
    // so the advertising-side consent has to follow ATT as well. Analytics
    // storage itself stays on: it is first-party measurement, not tracking.
    try {
      await FirebaseAnalytics.instance.setConsent(
        adStorageConsentGranted: personalised,
        adUserDataConsentGranted: personalised,
        adPersonalizationSignalsConsentGranted: personalised,
        analyticsStorageConsentGranted: true,
      );
    } catch (_) {
      // Ditto.
    }
  }
}
