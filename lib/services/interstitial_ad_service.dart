import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads and shows full-screen interstitial ads on app open.
///
/// Shows on every launch, including the first. The ad is preloaded ahead of
/// time via [preload] so [maybeShowOnLaunch] can show it immediately,
/// instead of stalling on a network load.
class InterstitialAdService {
  InterstitialAdService(this._prefs);

  final SharedPreferences _prefs;

  static const _launchCountKey = 'interstitial_launch_count';
  static const _showEveryNLaunches = 1;

  /// Wait before showing so the ad (a network load kicked off in `main()`)
  /// has time to finish; showing right after the first frame usually beats
  /// the load and silently skips the launch.
  static const _showDelay = Duration(seconds: 15);

  static const String _androidAdUnitId =
      'ca-app-pub-9425467580147795/3080033406';
  static const String _iosAdUnitId =
      'ca-app-pub-9425467580147795/1307056819';

  static String get _adUnitId =>
      Platform.isIOS ? _iosAdUnitId : _androidAdUnitId;

  InterstitialAd? _ad;
  bool _loading = false;

  /// Fetches the next ad in the background so it's ready by the time
  /// [maybeShowOnLaunch] needs it. Safe to call repeatedly (no-op while a
  /// load is in flight or an ad is already cached).
  void preload() {
    if (_loading || _ad != null) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (_) {
          _loading = false;
        },
      ),
    );
  }

  /// Bumps the launch counter and, if this launch lands on the cadence and a
  /// preloaded ad is ready, shows it. Best-effort: never throws — a missing
  /// or unready ad just means no ad this launch.
  Future<void> maybeShowOnLaunch() async {
    final count = (_prefs.getInt(_launchCountKey) ?? 0) + 1;
    await _prefs.setInt(_launchCountKey, count);
    if (count % _showEveryNLaunches != 0) return;

    await Future.delayed(_showDelay);

    final ad = _ad;
    if (ad == null) return;
    _ad = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        preload();
      },
    );
    await ad.show();
  }

  void dispose() {
    _ad?.dispose();
  }
}

final interstitialAdServiceProvider = Provider<InterstitialAdService>(
  (ref) => throw UnimplementedError(
    'interstitialAdServiceProvider must be overridden',
  ),
);
