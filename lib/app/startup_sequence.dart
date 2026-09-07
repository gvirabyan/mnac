import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/di/providers.dart';
import '../presentation/shared/state/settings_controller.dart';
import '../services/interstitial_ad_service.dart';
import '../services/notification_service.dart';
import '../services/push_service.dart';
import '../services/tracking_consent_service.dart';

/// Marks that the one-and-only notification permission prompt has been shown.
const String _notificationsAskedKey = 'notifications_permission_asked';

/// Everything that must wait for the splash screen to finish.
///
/// The system consent dialogs live here rather than in `main` because anything
/// raised before the first frame lands on top of the splash, hiding the very
/// branding it exists to show. The order matters and is deliberate:
///
///  1. Tracking (iOS). The Mobile Ads SDK reads the IDFA when it initialises,
///     so asking afterwards would leave the whole session non-personalised.
///  2. Notifications, immediately after, so a first launch presents its two
///     prompts back to back rather than spread across the session.
///  3. The ad SDK, now that tracking has been answered.
///  4. The broadcast topic, which on iOS registers with APNs — itself a source
///     of the notification prompt, hence strictly after step 2.
///
/// Every step is best-effort: a refusal at any point simply means less, never
/// a broken launch.
Future<void> runStartupSequence(WidgetRef ref) async {
  // Everything is read up front: the steps below wait on system dialogs, and
  // a ref touched after the widget behind it is gone throws.
  final prefs = ref.read(sharedPreferencesProvider);
  final notifications = ref.read(notificationServiceProvider);
  final push = ref.read(pushServiceProvider);
  final interstitialAds = ref.read(interstitialAdServiceProvider);
  final settings = ref.read(settingsControllerProvider.notifier);

  await const TrackingConsentService().request();
  await _askForNotificationsOnce(prefs, notifications, settings);

  await MobileAds.instance.initialize();
  interstitialAds.preload();

  await push.ensureSubscribed();
}

/// Requests notification permission the first time the app is opened.
///
/// Gated on a flag of its own rather than on the app's notification setting:
/// the OS remembers a refusal, so someone who declined — or who later switched
/// reminders off — must not be asked again on the next launch. Granting also
/// turns reminders on, the permission being worth nothing while the app's own
/// toggle stays off.
Future<void> _askForNotificationsOnce(
  SharedPreferences prefs,
  NotificationService notifications,
  SettingsController settings,
) async {
  if (prefs.getBool(_notificationsAskedKey) ?? false) return;

  final granted = await notifications.requestPermissions();
  // Recorded only once an answer is in, so a launch cut short while the system
  // dialog was still up asks again rather than losing the chance.
  await prefs.setBool(_notificationsAskedKey, true);
  if (!granted) return;

  await settings.setNotificationsEnabled(true);
}
