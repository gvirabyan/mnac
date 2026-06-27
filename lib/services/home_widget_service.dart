import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../core/l10n/app_strings.dart';
import '../core/utils/date_utils.dart';
import '../domain/entities/soldier_profile.dart';
import '../domain/usecases/compute_service_progress.dart';

/// Pushes the active soldier's countdown to the Android home-screen widget.
///
/// The widget UI is native (RemoteViews); here we only write the shared data
/// and request a refresh. Best-effort: platform errors are swallowed.
class HomeWidgetService {
  const HomeWidgetService();

  static const String _androidProvider = 'DepitunWidgetProvider';
  static const _compute = ComputeServiceProgress();

  Future<void> sync(SoldierProfile? soldier) async {
    try {
      if (soldier == null) {
        await HomeWidget.saveWidgetData<String>(
            'widget_title', AppStrings.appName);
        await HomeWidget.saveWidgetData<String>('widget_days', '—');
        await HomeWidget.saveWidgetData<String>('widget_discharge', '');
      } else {
        final progress = _compute(soldier, DateTime.now());
        await HomeWidget.saveWidgetData<String>(
          'widget_title',
          soldier.name ?? AppStrings.appName,
        );
        await HomeWidget.saveWidgetData<String>(
          'widget_days',
          '${progress.daysRemaining}',
        );
        await HomeWidget.saveWidgetData<String>(
          'widget_discharge',
          '${AppStrings.homeDischargeDate}՝ '
              '${AppDateUtils.formatLong(progress.end)} · ${progress.percentInt}%',
        );
      }
      await HomeWidget.updateWidget(androidName: _androidProvider);
    } catch (_) {
      // Widget unavailable (e.g. iOS, or no widget placed) — ignore.
    }
  }
}

final homeWidgetServiceProvider = Provider<HomeWidgetService>(
  (ref) => const HomeWidgetService(),
);
