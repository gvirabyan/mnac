import 'dart:async';
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

  /// Floor on how soon an ad may cover the app after launch. Deliberately not
  /// as early as the ad could be shown: landing an interstitial on someone a
  /// second into the app reads as broken, so the launch is given room first.
  static const _minDelay = Duration(seconds: 15);

  /// Extra time granted past [_minDelay] when the load is still in flight,
  /// so the worst case is the two added together.
  ///
  /// A mediation waterfall is sequential: every network above the one that
  /// eventually fills is called, times out, and only then is the next tried,
  /// so a fill can easily arrive 20s in. A fixed sleep gave up while the load
  /// was still running and dropped ads that arrived moments later — the wait
  /// now ends the instant the ad is ready and only falls back to this bound.
  static const _maxWait = Duration(seconds: 30);

  static const String _androidAdUnitId =
      'ca-app-pub-9425467580147795/9664465505';
  static const String _iosAdUnitId =
      'ca-app-pub-9425467580147795/1307056819';

  static String get _adUnitId =>
      Platform.isIOS ? _iosAdUnitId : _androidAdUnitId;

  InterstitialAd? _ad;
  bool _loading = false;

  /// Completes when the in-flight load settles, either way. Lets a waiting
  /// [maybeShowOnLaunch] wake up the instant the ad arrives.
  Completer<void>? _loadSettled;

  /// Fetches the next ad in the background so it's ready by the time
  /// [maybeShowOnLaunch] needs it. Safe to call repeatedly (no-op while a
  /// load is in flight or an ad is already cached).
  void preload() {
    if (_loading || _ad != null) return;
    _loading = true;
    _loadSettled = Completer<void>();
    final settled = _loadSettled!;
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
          // Which network actually filled the request. With mediation on this
          // is the only way to tell an AdMob-served ad from a Unity-served one
          // — the Unity adapter reports a class name containing "Unity".
          final adapter =
              ad.responseInfo?.mediationAdapterClassName ?? 'unknown adapter';
          if (!settled.isCompleted) settled.complete();
        },
        onAdFailedToLoad: (error) {
          _loading = false;
          // Code 3 is "no fill" — the request itself was fine, nobody had an
          // ad to serve at the configured floor. That distinguishes a broken
          // configuration from an empty market.
          if (!settled.isCompleted) settled.complete();
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

    await Future.delayed(_minDelay);

    if (_ad == null && _loading) {
      await _loadSettled?.future.timeout(_maxWait, onTimeout: () {});
    }

    final ad = _ad;
    if (ad == null) {
      // Either the load failed outright or it outran [_maxWait]. Said out loud
      // so an empty launch reads as "nothing was ready" rather than leaving it
      // ambiguous whether the ad code ran at all.
      return;
    }
    _ad = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
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
