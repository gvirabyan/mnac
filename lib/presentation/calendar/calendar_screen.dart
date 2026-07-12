import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/di/providers.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/utils/date_utils.dart';
import '../shared/state/soldiers_controller.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/glass_card.dart';
import '../shared/widgets/gradient_scaffold.dart';
import 'widgets/calendar_legend.dart';
import 'widgets/service_calendar.dart';

/// Calendar tab: a month view highlighting start, today, discharge, and
/// milestone days, with month navigation and a legend.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(activeSoldierProvider);

    // Milestone dates depend only on the profile (not the live clock), so we
    // compute them with `read` to avoid rebuilding the calendar every second.
    final milestoneDays = <DateTime>{};
    if (profile != null) {
      final snapshot =
          ref.read(computeServiceProgressProvider)(profile, DateTime.now());
      for (final m in ref.read(computeMilestonesProvider)(snapshot)) {
        milestoneDays.add(AppDateUtils.dateOnly(m.estimatedDate));
      }
    }

    return GradientScaffold(
      appBar: AppBar(title: const Text(AppStrings.calendarTitle)),
      body: profile == null
          ? const EmptyState(
              icon: Icons.calendar_today_outlined,
              title: AppStrings.homeNoSoldierTitle,
              subtitle: AppStrings.homeNoSoldierSubtitle,
            )
          : ListView(
              // Extra bottom inset so the last card scrolls clear of the
              // floating glass nav bar (the shell uses extendBody: true).
              padding: EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.md,
                AppSizes.screenPadding,
                AppSizes.xxl + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                _MonthHeader(
                  month: _month,
                  onPrev: () => _shiftMonth(-1),
                  onNext: () => _shiftMonth(1),
                ),
                const SizedBox(height: AppSizes.md),
                GlassCard(
                  child: ServiceCalendar(
                    month: _month,
                    start: profile.serviceStart,
                    discharge: profile.dischargeDate,
                    milestoneDays: milestoneDays,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                const CalendarLegend(),
              ],
            ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Text(
          AppDateUtils.formatMonthYear(month),
          style: theme.textTheme.titleLarge,
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}
