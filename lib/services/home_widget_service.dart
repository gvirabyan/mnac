import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show MethodChannel, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';

import '../core/l10n/app_strings.dart';
import '../core/utils/date_utils.dart';
import '../domain/entities/soldier_profile.dart';
import '../domain/usecases/compute_service_progress.dart';

/// Pushes every soldier's countdown to the home-screen widget (Android
/// RemoteViews; iOS WidgetKit extension).
///
/// The widget UI is native; here we only write the shared data and request a
/// refresh. The full list is serialised (active soldier first, see the
/// caller in `main_shell.dart`) so both platforms can page between soldiers
/// with a "next" button — Android via a broadcast receiver, iOS (17+) via an
/// `AppIntent`. Best-effort: platform errors are swallowed.
class HomeWidgetService {
  const HomeWidgetService();

  static const String _androidProvider = 'DepitunWidgetProvider';
  static const String _iosWidgetKind = 'DepitunWidgetExtension';
  static const String _appGroupId = 'group.com.virabyan.mnac.widget';
  static const String _defaultBackgroundAsset = 'assets/images/background.png';
  static const _compute = ComputeServiceProgress();

  /// Serialises [soldiers] (in display order) into the widget's shared data.
  Future<void> sync(List<SoldierProfile> soldiers) async {
    try {
      if (Platform.isIOS) {
        await HomeWidget.setAppGroupId(_appGroupId);
      }

      // Soldiers without a photo fall back to the app's own backdrop, so the
      // widget matches the home screen instead of showing a bare card.
      final defaultBackground = await _defaultBackgroundPath();

      final now = DateTime.now();
      final items = <Map<String, String>>[];
      for (var i = 0; i < soldiers.length; i++) {
        final soldier = soldiers[i];
        final progress = _compute(soldier, now);
        // A path recorded for a photo that has since been deleted would leave
        // the widget blank, so it's treated the same as no photo at all —
        // exactly what HomeBackground does in the app.
        final photo = soldier.photoPath;
        final hasPhoto = photo != null && File(photo).existsSync();
        // The iOS extension runs in a separate sandbox and can't read the
        // app's private photo file, so mirror every soldier's photo into the
        // shared App Group container (the widget can page to any of them).
        final String photoPath;
        if (!hasPhoto) {
          photoPath = defaultBackground ?? '';
        } else if (Platform.isIOS) {
          photoPath =
              await _sharedPhotoPath(photo, index: i) ?? defaultBackground ?? '';
        } else {
          photoPath = photo;
        }
        items.add({
          'title': soldier.name ?? AppStrings.appName,
          'days': '${progress.daysRemaining}',
          'percent': '${AppStrings.homeServedSoFar}՝ ${progress.percentInt}%',
          'discharge':
              '${AppStrings.homeDischargeDate}՝ '
              '${AppDateUtils.formatLong(progress.end)}',
          'photoPath': photoPath,
        });
      }

      await HomeWidget.saveWidgetData<String>(
        'widget_soldiers',
        jsonEncode(items),
      );
      await HomeWidget.updateWidget(
        androidName: _androidProvider,
        iOSName: _iosWidgetKind,
      );
    } catch (_) {
      // Widget unavailable (e.g. no widget placed) — ignore.
    }
  }

  /// Path to the bundled default backdrop, in storage the widget can read.
  ///
  /// It ships as a Flutter asset, which neither the Android provider nor the
  /// (sandboxed) iOS extension can open, so it is unpacked on first use:
  /// into the App Group container on iOS, the app's support directory on
  /// Android. Cached for the process — the bytes never change.
  static String? _defaultBackground;

  Future<String?> _defaultBackgroundPath() async {
    final cached = _defaultBackground;
    if (cached != null) return cached;

    try {
      final bytes = await rootBundle.load(_defaultBackgroundAsset);
      final data = bytes.buffer.asUint8List();

      String path;
      if (Platform.isIOS) {
        path = await HomeWidget.saveFile(
          'widget_default_background',
          data,
          extension: 'png',
        );
      } else {
        final dir = await getApplicationSupportDirectory();
        final file = File('${dir.path}/widget_default_background.png');
        if (!file.existsSync() || file.lengthSync() != data.length) {
          await file.writeAsBytes(data, flush: true);
        }
        path = file.path;
      }
      return _defaultBackground = path;
    } catch (_) {
      return null;
    }
  }

  /// Native side of [diagnostics].
  static const MethodChannel _iosDiagnostics =
      MethodChannel('com.virabyan.mnac/diagnostics');

  /// Why the iOS widget is showing its placeholder rather than a countdown.
  ///
  /// An empty widget looks the same whatever the cause, and none of it is
  /// visible from Dart: [sync] reports success as long as the plugin call
  /// returns, whether or not the write reached storage the extension can see.
  /// Empty on Android, where the widget reads the same process's data and
  /// there is no sharing step to go wrong.
  Future<String> diagnostics() async {
    if (!Platform.isIOS) return '';
    try {
      return await _iosDiagnostics.invokeMethod<String>('widget') ?? '';
    } catch (e) {
      return 'widget diagnostics: FAILED ($e)';
    }
  }

  /// Copies [sourcePath] into the App Group container so the (sandboxed) iOS
  /// widget extension can read it, returning the shared path. [index] keys
  /// the shared file so each soldier's photo survives independently.
  Future<String?> _sharedPhotoPath(
    String sourcePath, {
    required int index,
  }) async {
    try {
      final bytes = await File(sourcePath).readAsBytes();
      final ext = sourcePath.contains('.') ? sourcePath.split('.').last : 'jpg';
      return await HomeWidget.saveFile(
        'widget_photo_$index',
        bytes,
        extension: ext,
      );
    } catch (_) {
      return null;
    }
  }
}

final homeWidgetServiceProvider = Provider<HomeWidgetService>(
  (ref) => const HomeWidgetService(),
);
