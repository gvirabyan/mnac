import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/debug/debug_toast.dart';

/// Loads and shows full-screen interstitial ads on app open.
///
/// Capped to roughly every [_showEveryNLaunches]th launch (never the very
/// first one) so ads don't show on every open. The ad is preloaded ahead of
/// time via [preload] so [maybeShowOnLaunch] can show it immediately once
/// the launch cadence is due, instead of stalling on a network load.
class InterstitialAdService {
  InterstitialAdService(this._prefs);

  final SharedPreferences _prefs;

  static const _launchCountKey = 'interstitial_launch_count';
  // DEBUG: showing on every launch (including the first) to diagnose why
  // ads aren't appearing. Restore to 3 (and re-add the count <= 1 skip in
  // maybeShowOnLaunch) once debugging is done.
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
    if (_loading || _ad != null) {
      _log('preload skipped (loading=$_loading, cached=${_ad != null})');
      return;
    }
    _log('preload start, adUnitId=$_adUnitId');
    _loading = true;
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _log('ad loaded');
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (error) {
          _log('ad FAILED to load: $error');
          _loading = false;
        },
      ),
    );
  }

  /// Bumps the launch counter and, if this launch lands on the cadence,
  /// waits [_showDelay] for the preloaded ad to be ready and shows it.
  /// Best-effort: never throws — a missing or unready ad just means no ad
  /// this launch.
  Future<void> maybeShowOnLaunch() async {
    final count = (_prefs.getInt(_launchCountKey) ?? 0) + 1;
    await _prefs.setInt(_launchCountKey, count);
    _log('launch #$count');
    if (count % _showEveryNLaunches != 0) {
      _log('skipping this launch (cadence not due)');
      return;
    }

    _log('waiting $_showDelay for preload to finish');
    await Future.delayed(_showDelay);

    final ad = _ad;
    if (ad == null) {
      _log('no ad ready after delay — nothing to show');
      return;
    }
    _ad = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _log('ad dismissed');
        ad.dispose();
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _log('ad FAILED to show: $error');
        ad.dispose();
        preload();
      },
    );
    _log('showing ad');
    await ad.show();
  }

  void dispose() {
    _ad?.dispose();
  }

  void _log(String message) {
    developer.log(message, name: 'InterstitialAdService');
    showDebugToast('[Ad] $message');
  }
}

final interstitialAdServiceProvider = Provider<InterstitialAdService>(
  (ref) => throw UnimplementedError(
    'interstitialAdServiceProvider must be overridden',
  ),
);
