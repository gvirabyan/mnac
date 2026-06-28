import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../core/l10n/app_strings.dart';
import '../core/utils/date_utils.dart';
import '../domain/entities/soldier_profile.dart';
import '../domain/usecases/compute_service_progress.dart';

/// Pushes every soldier's countdown to the Android home-screen widget.
///
/// The widget UI is native (RemoteViews); here we only write the shared data
/// and request a refresh. The full list is serialised so the native side can
/// page between soldiers with the "next" button. Best-effort: platform errors
/// are swallowed.
class HomeWidgetService {
  const HomeWidgetService();

  static const String _androidProvider = 'DepitunWidgetProvider';
  static const _compute = ComputeServiceProgress();

  /// Serialises [soldiers] (in display order) into the widget's shared data.
  Future<void> sync(List<SoldierProfile> soldiers) async {
    try {
      final now = DateTime.now();
      final items = <Map<String, String>>[];
      for (final soldier in soldiers) {
        final progress = _compute(soldier, now);
        items.add({
          'title': soldier.name ?? AppStrings.appName,
          'days': '${progress.daysRemaining}',
          'percent': '${AppStrings.homeServedSoFar}՝ ${progress.percentInt}%',
          'discharge': '${AppStrings.homeDischargeDate}՝ '
              '${AppDateUtils.formatLong(progress.end)}',
          'photoPath': soldier.photoPath ?? '',
        });
      }

      await HomeWidget.saveWidgetData<String>(
        'widget_soldiers',
        jsonEncode(items),
      );
      await HomeWidget.updateWidget(androidName: _androidProvider);
    } catch (_) {
      // Widget unavailable (e.g. iOS, or no widget placed) — ignore.
    }
  }
}

final homeWidgetServiceProvider = Provider<HomeWidgetService>(
  (ref) => const HomeWidgetService(),
);
