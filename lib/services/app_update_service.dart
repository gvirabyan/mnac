import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_review/in_app_review.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/di/providers.dart';

/// A newer version waiting in the store, and how to offer it.
@immutable
class AppUpdate {
  const AppUpdate({
    required this.required,
    required this.key,
    this.messages = const {},
  });

  /// Below the `min_version` set in Firestore: no "later".
  final bool required;

  /// Identifies the store's version, so "later" holds for this one only.
  final String key;

  /// The owner's own text, by language id ("hy", "ru", "en"); empty when
  /// none was set, and the dialog says the usual.
  final Map<String, String> messages;
}

/// Finds out whether a newer version of the app is in the store, and takes
/// the user there.
///
/// The store itself says whether there is one: Google Play's in-app update
/// API on Android, the public App Store lookup on iOS. A version still in
/// review is not offered, nor is one Play has not rolled out to this device.
///
/// The owner can add, in Firestore `app_config/update`:
/// - `min_version` ("1.2.12"): anything older must update, no "later". Only
///   honoured once the store actually has an update for this device.
/// - `message_hy` / `message_ru` / `message_en`: the dialog's text.
///
/// "Later" hides the offer for [_snooze], or until a newer version than the
/// one put off comes out.
class AppUpdateService {
  AppUpdateService(this._prefs, {FirebaseFirestore? firestore})
      : _firestore = firestore;

  final SharedPreferences _prefs;
  final FirebaseFirestore? _firestore;

  static const _appStoreId = '6785097936';
  static const _bundleId = 'com.virabyan.mnac';
  static const _timeout = Duration(seconds: 8);
  static const _snooze = Duration(days: 3);

  static const _skippedKey = 'update_skipped_key';
  static const _skippedAtKey = 'update_skipped_at';

  /// The update to offer on this launch, or null. Never throws: anything
  /// that goes wrong (offline, debug build, not installed from Play) means
  /// no offer.
  Future<AppUpdate?> check() async {
    try {
      final current = (await PackageInfo.fromPlatform()).version;
      final (storeKey, storeVersion) = await _storeUpdate(current);
      if (storeKey == null) return null;

      final config = await _config();
      final min = config['min_version'];
      // Required only for what the store can deliver: on iOS the store's
      // version must reach the minimum; Play's version code can't be
      // compared to it, but an update there is the newest one anyway.
      final required = min is String &&
          _compare(current, min) < 0 &&
          (storeVersion == null || _compare(storeVersion, min) >= 0);

      if (!required && _snoozed(storeKey)) return null;
      return AppUpdate(
        required: required,
        key: storeKey,
        messages: {
          for (final lang in const ['hy', 'ru', 'en'])
            if (config['message_$lang'] case final String m
                when m.trim().isNotEmpty)
              lang: m.trim(),
        },
      );
    } catch (e) {
      debugPrint('[UPDATE] check failed: $e');
      return null;
    }
  }

  /// "Later": not again for [_snooze], unless a newer version comes out.
  Future<void> snooze(AppUpdate update) async {
    await _prefs.setString(_skippedKey, update.key);
    await _prefs.setInt(
      _skippedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Starts the update. On Android, Play's own full-screen update, which
  /// restarts the app when done, or the store page should that fail; on
  /// iOS, the App Store page.
  Future<void> startUpdate() async {
    if (Platform.isAndroid) {
      try {
        final result = await InAppUpdate.performImmediateUpdate();
        // Done, or turned down in Play's own screen: nothing more to do.
        if (result != AppUpdateResult.inAppUpdateFailed) return;
      } catch (e) {
        debugPrint('[UPDATE] in-app update failed: $e');
      }
    }
    await InAppReview.instance.openStoreListing(appStoreId: _appStoreId);
  }

  /// The store's update for this device as (key, version), or (null, null)
  /// when there is none. The version is known on iOS only.
  Future<(String?, String?)> _storeUpdate(String current) async {
    if (Platform.isAndroid) {
      final info = await InAppUpdate.checkForUpdate().timeout(_timeout);
      if (info.updateAvailability != UpdateAvailability.updateAvailable ||
          !info.immediateUpdateAllowed) {
        return (null, null);
      }
      return ('android:${info.availableVersionCode}', null);
    }
    if (Platform.isIOS) {
      final uri = Uri.https('itunes.apple.com', '/lookup', {
        'bundleId': _bundleId,
        // Past any cached answer from before the release.
        't': '${DateTime.now().millisecondsSinceEpoch ~/ 60000}',
      });
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return (null, null);
      final results = (jsonDecode(response.body) as Map)['results'] as List;
      if (results.isEmpty) return (null, null);
      final version = (results.first as Map)['version'];
      if (version is! String || _compare(version, current) <= 0) {
        return (null, null);
      }
      return ('ios:$version', version);
    }
    return (null, null);
  }

  /// `app_config/update`, or empty when it is missing or unreachable.
  Future<Map<String, dynamic>> _config() async {
    try {
      final doc = await (_firestore ?? FirebaseFirestore.instance)
          .collection('app_config')
          .doc('update')
          .get()
          .timeout(_timeout);
      return doc.data() ?? const {};
    } catch (e) {
      debugPrint('[UPDATE] no config: $e');
      return const {};
    }
  }

  bool _snoozed(String key) {
    if (_prefs.getString(_skippedKey) != key) return false;
    final at = _prefs.getInt(_skippedAtKey);
    if (at == null) return false;
    final since = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(at),
    );
    return since < _snooze;
  }

  /// Compares dotted versions ("1.2.12" vs "1.2.9") part by part; a build
  /// suffix ("+47") is ignored.
  static int _compare(String a, String b) {
    List<int> parts(String v) => v
        .split('+')
        .first
        .split('.')
        .map((p) => int.tryParse(p.trim()) ?? 0)
        .toList();
    final x = parts(a);
    final y = parts(b);
    for (var i = 0; i < x.length || i < y.length; i++) {
      final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
      if (d != 0) return d.sign;
    }
    return 0;
  }
}

final appUpdateServiceProvider = Provider<AppUpdateService>(
  (ref) => AppUpdateService(ref.watch(sharedPreferencesProvider)),
);
