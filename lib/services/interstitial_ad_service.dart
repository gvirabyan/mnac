import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/l10n/app_language.dart';
import '../core/l10n/app_strings.dart';

/// Loads and shows full-screen interstitial ads on app open.
///
/// Shows on every launch, including the first. The ad is preloaded ahead of
/// time via [preload] so [maybeShowOnLaunch] can show it immediately,
/// instead of stalling on a network load.
///
/// Never while the app is in Armenian: Google's publisher policies forbid ads
/// on screens whose content is in an unsupported language, and Armenian is
/// one. Checked both before the request and again before showing, so a
/// language switch during the launch delay is respected either way.
class InterstitialAdService {
  InterstitialAdService(this._prefs);

  final SharedPreferences _prefs;

  /// Whether the ad request may be personalised. Starts out false so a request
  /// fired before the App Tracking Transparency answer is in errs towards no
  /// tracking; [setPersonalisedAds] raises it once the user has authorised.
  bool _personalised = false;

  /// Records the App Tracking Transparency outcome. Call before [preload].
  void setPersonalisedAds({required bool personalised}) {
    _personalised = personalised;
  }

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

  /// False while the app is in Armenian; nothing ad-related may run then,
  /// the SDK's own start-up included.
  static bool get adsAllowed => AppStrings.language != AppLanguage.hy;

  InterstitialAd? _ad;
  bool _loading = false;

  /// Completes when the in-flight load settles, either way. Lets a waiting
  /// [maybeShowOnLaunch] wake up the instant the ad arrives.
  Completer<void>? _loadSettled;

  /// Fetches the next ad in the background so it's ready by the time
  /// [maybeShowOnLaunch] needs it. Safe to call repeatedly (no-op while a
  /// load is in flight or an ad is already cached).
  void preload() {
    if (!adsAllowed) {
      debugPrint('[ADS] no request: app is in Armenian'); // TEMP
      return;
    }
    if (_loading || _ad != null) return;
    _loading = true;
    _loadSettled = Completer<void>();
    final settled = _loadSettled!;
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: AdRequest(nonPersonalizedAds: !_personalised),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
          // Which network actually filled the request. With mediation on this
          // is the only way to tell an AdMob-served ad from a Unity- or
          // InMobi-served one — each adapter's class name carries its network.
          final adapter =
              ad.responseInfo?.mediationAdapterClassName ?? 'unknown adapter';
          debugPrint('[ADS] loaded by $adapter'); // TEMP
          _logNetworks(ad.responseInfo); // TEMP
          if (!settled.isCompleted) settled.complete();
        },
        onAdFailedToLoad: (error) {
          debugPrint('[ADS] load failed: ${error.code} ${error.message}'); // TEMP
          _logNetworks(error.responseInfo); // TEMP
          _loading = false;
          // Code 3 is "no fill" — the request itself was fine, nobody had an
          // ad to serve at the configured floor. That distinguishes a broken
          // configuration from an empty market.
          if (!settled.isCompleted) settled.complete();
        },
      ),
    );
  }

  // TEMP: mediation check — remove. One line per network AdMob tried, in
  // order, with what each answered.
  static void _logNetworks(ResponseInfo? info) {
    for (final r in info?.adapterResponses ?? const <AdapterResponseInfo>[]) {
      debugPrint('[ADS]   ${r.adSourceName} (${r.adapterClassName}): '
          '${r.adError == null ? 'filled' : 'error ${r.adError!.code} ${r.adError!.message}'}'
          ' ${r.latencyMillis}ms');
    }
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
    if (!adsAllowed) {
      ad.dispose();
      return;
    }

    // No preload for a next ad here: one ad per launch, and the next launch
    // starts a fresh process that loads its own, so an ad fetched now would
    // never be shown — just a second request per launch that halves the show
    // rate in AdMob. Bring the preload back if ads ever show more than once
    // in a session.
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) => ad.dispose(),
      onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
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
