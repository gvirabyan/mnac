import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/l10n/app_strings.dart';
import '../../services/home_widget_service.dart';
import '../../services/notification_service.dart';
import '../calendar/calendar_screen.dart';
import '../home/home_controller.dart';
import '../home/home_screen.dart';
import '../milestones/milestone_celebration.dart';
import '../milestones/milestones_controller.dart';
import '../settings/settings_screen.dart';
import '../shared/state/immersive_controller.dart';
import '../shared/state/settings_controller.dart';
import '../shared/state/soldiers_controller.dart';
import '../statistics/statistics_screen.dart';
import 'glass_nav_bar.dart';

/// The main navigation shell: four tabs (Home / Statistics / Calendar /
/// Settings) hosted in an [IndexedStack] to preserve each tab's state.
///
/// Also hosts the app-wide milestone celebration listener so a newly reached
/// milestone is celebrated and persisted regardless of the active tab.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  int _index = 0;
  bool _celebrating = false;

  static const _screens = [
    HomeScreen(),
    StatisticsScreen(),
    CalendarScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncBackground());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-syncing on resume cancels today's reminder once the user opens the app.
    if (state == AppLifecycleState.resumed) _syncBackground();
  }

  Future<void> _syncBackground() async {
    final soldier = ref.read(activeSoldierProvider);
    final settings = ref.read(settingsControllerProvider);
    final quotes = ref.read(quotesProvider).value ?? const <String>[];
    await ref.read(notificationServiceProvider).sync(
          soldier: soldier,
          settings: settings,
          quotes: quotes,
        );
    final soldiers = ref.read(soldiersControllerProvider).soldiers;
    await ref.read(homeWidgetServiceProvider).sync(soldiers);
  }

  Future<void> _celebrate(int threshold) async {
    if (_celebrating) return;
    _celebrating = true;

    // Persist all currently-unlocked thresholds so this fires only once.
    final progress = ref.read(serviceProgressProvider);
    if (progress != null) {
      final unlocked =
          ref.read(computeMilestonesProvider).unlockedThresholds(progress);
      await ref
          .read(settingsControllerProvider.notifier)
          .markMilestonesUnlocked(unlocked);
    }

    if (!mounted) return;
    await showMilestoneCelebration(context, threshold);
    _celebrating = false;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(pendingCelebrationProvider, (previous, next) {
      if (next != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _celebrate(next);
        });
      }
    });

    // Re-schedule notifications when the active soldier or notification
    // settings change.
    ref.listen(activeSoldierProvider, (_, _) => _syncBackground());
    ref.listen<({bool enabled, bool daily, int minutes, bool milestones})>(
      settingsControllerProvider.select(
        (s) => (
          enabled: s.notificationsEnabled,
          daily: s.dailyReminderEnabled,
          minutes: s.dailyReminderMinutes,
          milestones: s.milestoneNotificationsEnabled,
        ),
      ),
      (_, _) => _syncBackground(),
    );

    // Hide the navigation bar while the home screen is in immersive mode.
    final immersive = ref.watch(immersiveProvider);

    return Scaffold(
      // Let screen content flow behind the translucent glass nav bar.
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: immersive
          ? null
          : GlassNavBar(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
              items: const [
                GlassNavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: AppStrings.navHome,
                ),
                GlassNavItem(
                  icon: Icons.insights_outlined,
                  selectedIcon: Icons.insights_rounded,
                  label: AppStrings.navStats,
                ),
                GlassNavItem(
                  icon: Icons.calendar_today_outlined,
                  selectedIcon: Icons.calendar_today_rounded,
                  label: AppStrings.navCalendar,
                ),
                GlassNavItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings_rounded,
                  label: AppStrings.navSettings,
                ),
              ],
            ),
    );
  }
}
