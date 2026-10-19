import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/di/providers.dart';

/// Decides when to ask for a store rating, and opens the store's review.
///
/// Counts cold starts. The first ask comes after [_firstAskAt] launches, so
/// the app has been used for a while; "not now" pushes the next one
/// [_snoozeLaunches] further out, and after [_maxAsks] asks, or once the user
/// has gone to rate, it never asks again. Android asks with the app's own
/// dialog, iOS with the system sheet directly, see [usesOwnDialog].
class RateAppService {
  RateAppService(this._prefs, {InAppReview? review})
      : _review = review ?? InAppReview.instance;

  final SharedPreferences _prefs;
  final InAppReview _review;

  static const _launchCountKey = 'rate_launch_count';
  static const _nextAskAtKey = 'rate_next_ask_at';
  static const _askCountKey = 'rate_ask_count';
  static const _doneKey = 'rate_done';

  static const _firstAskAt = 5;
  static const _snoozeLaunches = 10;
  static const _maxAsks = 3;

  int get _launches => _prefs.getInt(_launchCountKey) ?? 0;

  /// Call once per cold start.
  Future<void> recordLaunch() =>
      _prefs.setInt(_launchCountKey, _launches + 1);

  bool get shouldAsk {
    if (_prefs.getBool(_doneKey) ?? false) return false;
    if ((_prefs.getInt(_askCountKey) ?? 0) >= _maxAsks) return false;
    return _launches >= (_prefs.getInt(_nextAskAtKey) ?? _firstAskAt);
  }

  /// Records an ask as soon as the dialog is up, so an app closed over it
  /// counts as "not now" rather than asking again on the next launch.
  Future<void> markAsked() async {
    await _prefs.setInt(_askCountKey, (_prefs.getInt(_askCountKey) ?? 0) + 1);
    await _prefs.setInt(_nextAskAtKey, _launches + _snoozeLaunches);
  }

  /// Whether the app asks with its own dialog first. Only on Android: on
  /// iOS, App Store guideline 5.6.1 wants ratings asked for through the
  /// system sheet alone, and that sheet may decline to appear, which would
  /// leave a "Rate" button doing nothing. iOS goes to [requestSystemReview].
  bool get usesOwnDialog => Platform.isAndroid;

  /// Takes the user to the Play listing, and stops asking.
  ///
  /// The listing rather than the in-app review sheet: Play rations that
  /// sheet and silently skips it when over quota, which would leave a tap on
  /// "Rate" doing nothing.
  Future<void> rate() async {
    await _prefs.setBool(_doneKey, true);
    try {
      await _review.openStoreListing();
    } catch (_) {
      // Best-effort: no store app, or the store refused.
    }
  }

  /// Asks the system for its review sheet, on iOS. Apple decides whether it
  /// actually shows (never in TestFlight, at most three times a year, not
  /// for someone who already rated), and never says, so asking does not
  /// stop the next asks; [_maxAsks] still caps them.
  Future<void> requestSystemReview() async {
    try {
      if (await _review.isAvailable()) await _review.requestReview();
    } catch (_) {
      // Best-effort.
    }
  }
}

final rateAppServiceProvider = Provider<RateAppService>(
  (ref) => RateAppService(ref.watch(sharedPreferencesProvider)),
);
