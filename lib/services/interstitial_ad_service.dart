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
/// Shows on every launch after an ad-free start (see [_adFreeLaunches]):
/// - Android in Armenian: the first [_androidArmenianAdFreeLaunches]
///   launches, for everyone, people who update included.
/// - Everywhere else: the first [_newcomerAdFreeLaunches] launches, only for
///   people who install fresh; people who update see ads straight away.
///
/// The ad is preloaded ahead of time via [preload] so [maybeShowOnLaunch]
/// can show it immediately, instead of stalling on a network load.
///
/// Note: Google's publisher policies do not support Armenian as a content
/// language, so serving AdMob ads on the Android app's Armenian screens goes
/// against them and risks the AdMob account. This was a deliberate choice
/// by the app's owner (Nov 2026); until then the Armenian Android app showed
/// no ads at all.
class InterstitialAdService {
  InterstitialAdService(this._prefs, {required bool isFreshInstall})
      : _launchNumber = (_prefs.getInt(_launchCountKey) ?? 0) + 1,
        _isNewcomer = _prefs.getBool(_newcomerKey) ?? isFreshInstall {
    // Counted here, once per process, rather than when the ad is due: the
    // preload, which runs first, needs to know which launch this is too.
    _prefs.setInt(_launchCountKey, _launchNumber);
    // Decided once, on the first launch of the version that brought this in,
    // and kept: a newcomer stays one even after the settings are saved.
    _prefs.setBool(_newcomerKey, _isNewcomer);
    // The count older versions kept. Left alone it would carry people who
    // update straight past the Armenian ad-free start, so counting begins
    // afresh.
    _prefs.remove(_oldLaunchCountKey);
  }

  final SharedPreferences _prefs;

  /// Which app launch this is, 1 being the first after install or after the
  /// update that brought in the ad-free start.
  final int _launchNumber;

  /// Whether this install is a fresh one (as opposed to an update of a
  /// version from before the ad-free start).
  final bool _isNewcomer;

  /// Started with the service in `main`, so [_minDelay] counts from launch
  /// rather than from whenever [maybeShowOnLaunch] is reached.
  final Stopwatch _sinceLaunch = Stopwatch()..start();

  /// Whether the ad request may be personalised. Starts out false so a request
  /// fired before the App Tracking Transparency answer is in errs towards no
  /// tracking; [setPersonalisedAds] raises it once the user has authorised.
  bool _personalised = false;

  /// Records the App Tracking Transparency outcome. Call before [preload].
  void setPersonalisedAds({required bool personalised}) {
    _personalised = personalised;
  }

  static const _launchCountKey = 'ad_launch_count';
  static const _oldLaunchCountKey = 'interstitial_launch_count';
  static const _newcomerKey = 'ad_is_newcomer';
  static const _showEveryNLaunches = 1;

  /// Launches with no ad on Android while the app is in Armenian, for
  /// everyone: after install and, for people who already had the app, after
  /// updating to the version that brought this in.
  static const _androidArmenianAdFreeLaunches = 5;

  /// Launches with no ad everywhere else, for fresh installs only.
  static const _newcomerAdFreeLaunches = 2;

  /// How many first launches go without an ad, for this platform, language
  /// and install. Read at each check, so a language switch counts at once.
  int get _adFreeLaunches {
    if (Platform.isAndroid && AppStrings.language == AppLanguage.hy) {
      return _androidArmenianAdFreeLaunches;
    }
    return _isNewcomer ? _newcomerAdFreeLaunches : 0;
  }

  /// True while this launch is one of the ad-free first ones. Nothing is even
  /// requested then: a fetched ad left unshown only drags down the show rate
  /// in AdMob.
  bool get _inAdFreeStart => _launchNumber <= _adFreeLaunches;

  /// Floor on how soon after launch an ad may cover the app. Deliberately not
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

  /// Opens Google's Ad Inspector, which shows each mediation network's
  /// setup and how it answered the latest requests. Completes once it is
  /// closed: null when all went well, otherwise why it would not open — it
  /// only opens on a device registered as a test device in the AdMob console.
  static Future<String?> openAdInspector() {
    final closed = Completer<String?>();
    MobileAds.instance.openAdInspector((error) {
      closed.complete(
        error == null ? null : 'Ad Inspector: ${error.code} ${error.message}',
      );
    });
    return closed.future;
  }

  InterstitialAd? _ad;
  bool _loading = false;

  /// Completes when the in-flight load settles, either way. Lets a waiting
  /// [maybeShowOnLaunch] wake up the instant the ad arrives.
  Completer<void>? _loadSettled;

  /// Fetches the next ad in the background so it's ready by the time
  /// [maybeShowOnLaunch] needs it. Safe to call repeatedly (no-op while a
  /// load is in flight or an ad is already cached).
  void preload() {
    if (_inAdFreeStart) {
      debugPrint('[ADS] no request: launch $_launchNumber of the first '
          '$_adFreeLaunches ad-free ones'); // TEMP
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
    final responses = info?.adapterResponses ?? const <AdapterResponseInfo>[];
    for (final r in responses) {
      debugPrint('[ADS]   ${r.adSourceName} (${r.adapterClassName}): '
          '${r.adError == null ? 'filled' : 'error ${r.adError!.code} ${r.adError!.message}'}'
          ' ${r.latencyMillis}ms');
    }
    // Meta on a line of its own, "not asked" included: an adapter AdMob never
    // calls is the one failure that otherwise leaves no trace at all.
    final meta = responses.where((r) => isMetaAdapter(r.adapterClassName));
    debugPrint(meta.isEmpty
        ? '[ADS] Meta: not asked for this request'
        : '[ADS] Meta: ${meta.map((r) => r.adError == null ? 'filled' : 'error ${r.adError!.code} ${r.adError!.message}').join('; ')}');
  }

  /// Meta's adapter class, on either platform: `FacebookMediationAdapter` on
  /// Android, `GADMediationAdapterMeta` (formerly `...Facebook`) on iOS.
  static bool isMetaAdapter(String name) {
    final n = name.toLowerCase();
    return n.contains('facebook') || n.contains('meta');
  }

  /// If this launch lands on the cadence, is past the ad-free start, and a
  /// preloaded ad is ready, shows it. Best-effort: never throws — a missing
  /// or unready ad just means no ad this launch. When an ad is shown, the
  /// future completes only after it is closed.
  Future<void> maybeShowOnLaunch() async {
    if (_inAdFreeStart) return;
    if (_launchNumber % _showEveryNLaunches != 0) return;

    // Only what is left of it: time spent on the day's milestone dialog,
    // shown first, already counts.
    final remaining = _minDelay - _sinceLaunch.elapsed;
    if (remaining > Duration.zero) await Future.delayed(remaining);

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
    // Checked again: a switch to Armenian on Android during the launch delay
    // can put this launch back inside the longer ad-free start.
    if (_inAdFreeStart) {
      ad.dispose();
      return;
    }

    // No preload for a next ad here: one ad per launch, and the next launch
    // starts a fresh process that loads its own, so an ad fetched now would
    // never be shown — just a second request per launch that halves the show
    // rate in AdMob. Bring the preload back if ads ever show more than once
    // in a session.
    // Completes only once the ad has left the screen. `show()` itself returns
    // as soon as the ad is presented, and the caller's dialogs (milestone,
    // rating) would then land on top of the ad instead of after it.
    final gone = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!gone.isCompleted) gone.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!gone.isCompleted) gone.complete();
      },
    );
    await ad.show();
    await gone.future;
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
