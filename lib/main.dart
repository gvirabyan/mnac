import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/di/providers.dart';
import 'data/datasources/local_prefs_data_source.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'data/repositories/soldiers_repository_impl.dart';
import 'firebase_options.dart';
import 'presentation/home/home_controller.dart';
import 'services/interstitial_ad_service.dart';
import 'services/notification_service.dart';
import 'services/push_service.dart';
import 'services/tracking_consent_service.dart';

/// Marks that the one-and-only notification permission prompt has been shown.
const String _notificationsAskedKey = 'notifications_permission_asked';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize local storage and preload data so the first frame is correct.
  final prefs = await SharedPreferences.getInstance();
  final dataSource = LocalPrefsDataSource(prefs);
  final settingsRepo = SettingsRepositoryImpl(dataSource);
  var settings = await settingsRepo.load();
  final soldiersRepo = SoldiersRepositoryImpl(dataSource);
  final soldiers = await soldiersRepo.loadAll();
  final activeId = await soldiersRepo.loadActiveId();

  final notifications = NotificationService();
  await notifications.init();

  // Broadcast pushes. Only the listener for now — joining the topic raises the
  // notification prompt on iOS, and that has to wait its turn below.
  final push = PushService(notifications);
  push.init();

  // ATT first: on iOS the Mobile Ads SDK reads the IDFA at initialize time, so
  // asking afterwards would leave the whole first session non-personalised.
  // Whatever the user answers, startup continues.
  await const TrackingConsentService().request();

  // Then notifications, so on a first launch the two system prompts follow one
  // another instead of being spread across the session. Asked once ever: the
  // OS remembers a refusal, and re-prompting someone who declined — or who
  // later switched reminders off — would just be noise. Granting turns
  // reminders on, since the permission is worth nothing while the app's own
  // toggle stays off.
  if (!(prefs.getBool(_notificationsAskedKey) ?? false)) {
    final granted = await notifications.requestPermissions();
    await prefs.setBool(_notificationsAskedKey, true);
    if (granted) {
      settings = settings.copyWith(notificationsEnabled: true);
      await settingsRepo.save(settings);
    }
  }

  // Now that the prompt is out of the way, join the broadcast topic. Not
  // awaited: on iOS this waits on APNs for seconds, and the first frame must
  // not be held for it.
  unawaited(push.ensureSubscribed());

  // The adapter statuses answer the "is Unity actually wired in?" question on
  // their own, before any ad request: an adapter missing from this map isn't
  // linked into the build at all, which is a different problem from one that
  // is linked but never gets a fill.
  final adsStatus = await MobileAds.instance.initialize();
  final adapters = adsStatus.adapterStatuses.entries
      .map((e) => '${e.key.split('.').last}=${e.value.state.name}')
      .toList();
  final hasUnity = adapters.any((a) => a.toLowerCase().contains('unity'));
  // Stated as a verdict rather than left to be inferred from the list: an
  // adapter absent here isn't linked into the build at all, which is a wholly
  // different problem from one that is linked but never wins a fill.
  final interstitialAds = InterstitialAdService(prefs);
  interstitialAds.preload();

  // Preload motivational quotes so the home quote shows on the very first frame
  // (returning a non-Future from overrideWith makes the value available
  // synchronously, avoiding an empty banner right after adding a soldier).
  // Guarded so a malformed asset degrades to lazy loading instead of crashing.
  List<String>? quotes;
  try {
    final quotesRaw = await rootBundle.loadString(
      'assets/quotes/quotes_hy.json',
    );
    quotes = (jsonDecode(quotesRaw) as List).cast<String>();
  } catch (_) {
    quotes = null;
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialSettingsProvider.overrideWithValue(settings),
        initialSoldiersProvider.overrideWithValue(soldiers),
        initialActiveIdProvider.overrideWithValue(activeId),
        notificationServiceProvider.overrideWithValue(notifications),
        pushServiceProvider.overrideWithValue(push),
        interstitialAdServiceProvider.overrideWithValue(interstitialAds),
        if (quotes != null) quotesProvider.overrideWith((ref) => quotes!),
      ],
      child: const DepiTunApp(),
    ),
  );
}
