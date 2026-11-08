import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Unity Ads called directly, without AdMob — Android, Armenian mode only.
///
/// A thin bridge to `UnityAdsChannel.kt`. Every call answers with null on
/// success or the reason it failed, and never throws: an ad that can't be had
/// just means no ad this launch.
class UnityDirectAds {
  const UnityDirectAds();

  static const _channel = MethodChannel('com.virabyan.mnac/unity_ads');

  // From Unity Dashboard: the Android Game ID (iOS is 6170644 — not used
  // here) and an interstitial ad unit of its own, kept apart from the one
  // AdMob mediates so the Armenian mode's revenue shows separately. Emptying
  // either turns the Armenian mode back to ad-free.
  static const String _gameId = '6170645';
  static const String _placementId = 'Interstitial_Android_Direct';

  static bool get configured => _gameId.isNotEmpty && _placementId.isNotEmpty;

  /// Debug builds ask Unity for test ads, so development never serves (or
  /// clicks) real ones. Release builds get real ads.
  Future<String?> initialize() =>
      _call('initialize', {'gameId': _gameId, 'testMode': kDebugMode});

  Future<String?> load() => _call('load', {'placementId': _placementId});

  /// Completes once the ad has been closed (or failed to show).
  Future<String?> show() => _call('show', {'placementId': _placementId});

  static Future<String?> _call(String method, Map<String, Object?> args) async {
    try {
      return await _channel.invokeMethod<String>(method, args);
    } on PlatformException catch (e) {
      return '$method: ${e.code} ${e.message}';
    } on MissingPluginException {
      return '$method: no Unity channel on this platform';
    }
  }
}
