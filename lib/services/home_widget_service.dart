import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

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
  static const _compute = ComputeServiceProgress();

  /// Serialises [soldiers] (in display order) into the widget's shared data.
  Future<void> sync(List<SoldierProfile> soldiers) async {
    try {
      if (Platform.isIOS) {
        await HomeWidget.setAppGroupId(_appGroupId);
      }

      final now = DateTime.now();
      final items = <Map<String, String>>[];
      for (var i = 0; i < soldiers.length; i++) {
        final soldier = soldiers[i];
        final progress = _compute(soldier, now);
        // The iOS extension runs in a separate sandbox and can't read the
        // app's private photo file, so mirror every soldier's photo into the
        // shared App Group container (the widget can page to any of them).
        var photoPath = soldier.photoPath ?? '';
        if (Platform.isIOS && soldier.photoPath != null) {
          photoPath =
              await _sharedPhotoPath(soldier.photoPath!, index: i) ?? '';
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
