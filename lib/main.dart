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
import 'services/ad_debug.dart';
import 'services/interstitial_ad_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize local storage and preload data so the first frame is correct.
  final prefs = await SharedPreferences.getInstance();
  final dataSource = LocalPrefsDataSource(prefs);
  final settings = await SettingsRepositoryImpl(dataSource).load();
  final soldiersRepo = SoldiersRepositoryImpl(dataSource);
  final soldiers = await soldiersRepo.loadAll();
  final activeId = await soldiersRepo.loadActiveId();

  final notifications = NotificationService();
  await notifications.init();

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
  logAdEvent(hasUnity ? 'UNITY ADAPTER PRESENT' : 'UNITY ADAPTER MISSING');
  logAdEvent('adapters: ${adapters.join(', ')}');
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
        interstitialAdServiceProvider.overrideWithValue(interstitialAds),
        if (quotes != null) quotesProvider.overrideWith((ref) => quotes!),
      ],
      child: const DepiTunApp(),
    ),
  );
}
