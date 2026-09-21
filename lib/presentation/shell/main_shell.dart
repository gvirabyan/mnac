import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/l10n/app_strings.dart';
import '../../domain/entities/milestone.dart';
import '../../services/home_widget_service.dart';
import '../../services/interstitial_ad_service.dart';
import '../../services/notification_service.dart';
import '../../services/push_service.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncBackground();
      // Cold-start only — deliberately not repeated on resume, so the ad
      // cadence tracks app opens rather than every foreground/background flip.
      // The milestone dialog waits for the ad to be done with the screen.
      ref
          .read(interstitialAdServiceProvider)
          .maybeShowOnLaunch()
          .whenComplete(_maybeShowTodaysMilestone);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-syncing on resume cancels today's reminder once the user opens the app.
    if (state != AppLifecycleState.resumed) return;
    // Permission first: it decides whether the sync has anything to schedule.
    _reconcileNotificationPermission().then((_) => _syncBackground());
    // A milestone crossed while the app sat in the background belongs to the
    // day the user comes back, not to the next cold start.
    _maybeShowTodaysMilestone();
  }

  /// Brings the app's notification setting back in line with what the OS
  /// actually allows, which can have changed while the app was away.
  ///
  /// Two directions, deliberately not symmetric:
  ///
  /// * Revoked in the system settings — the setting goes off, so the switch
  ///   stops promising reminders that can never be delivered.
  /// * Granted in the system settings — the setting comes on only if the user
  ///   was sent there from the toggle (see [notificationsPendingEnableKey]).
  ///   Otherwise an allowed permission would keep forcing reminders back on
  ///   for someone who simply switched them off in the app.
  Future<void> _reconcileNotificationPermission() async {
    final granted = await ref.read(notificationServiceProvider).hasPermission();
    if (!mounted) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final settings = ref.read(settingsControllerProvider);
    final notifier = ref.read(settingsControllerProvider.notifier);

    if (!granted) {
      if (settings.notificationsEnabled) {
        await notifier.setNotificationsEnabled(false);
      }
      return;
    }

    if (!(prefs.getBool(notificationsPendingEnableKey) ?? false)) return;
    await prefs.remove(notificationsPendingEnableKey);
    if (settings.notificationsEnabled) return;

    await notifier.update(
      (s) => s.copyWith(notificationsEnabled: true, dailyReminderEnabled: true),
    );
    if (!mounted) return;
    unawaited(ref.read(pushServiceProvider).ensureSubscribed());
  }

  Future<void> _syncBackground() async {
    final soldier = ref.read(activeSoldierProvider);
    final settings = ref.read(settingsControllerProvider);
    final quotes = ref.read(quotesProvider).value ?? const <String>[];
    await ref
        .read(notificationServiceProvider)
        .sync(soldier: soldier, settings: settings, quotes: quotes);
    final soldiers = ref.read(soldiersControllerProvider).soldiers;
    // The widget always shows list index 0 (Android's "next" button pages
    // from there); reorder so the active soldier — the one whose photo is
    // shown as the app's home background — leads, regardless of storage order.
    final ordered = soldier == null
        ? soldiers
        : [
            ...soldiers.where((s) => s.id == soldier.id),
            ...soldiers.where((s) => s.id != soldier.id),
          ];
    await ref.read(homeWidgetServiceProvider).sync(ordered);
  }

  /// Opens the day's milestone once a day.
  ///
  /// This, rather than [pendingCelebrationProvider], is what shows a milestone
  /// crossed while the app was closed: the listener below only fires on a
  /// change, and a milestone reached overnight is already in place by the time
  /// anything starts listening.
  Future<void> _maybeShowTodaysMilestone() async {
    if (_celebrating || !mounted) return;

    final milestone = ref.read(todaysMilestoneProvider);
    if (milestone == null) return;

    final tag = _recapTag(milestone);
    if (tag == null) return;
    final prefs = ref.read(sharedPreferencesProvider);
    if ((prefs.getStringList(milestoneRecapShownKey) ?? const [])
        .contains(tag)) {
      return;
    }

    // Anything not yet celebrated is news and gets the full treatment;
    // something already marked is a recap of the day, opened quietly.
    await _celebrate(milestone, alreadyReached: !milestone.justUnlocked);
  }

  Future<void> _celebrate(
    Milestone milestone, {
    bool alreadyReached = false,
  }) async {
    if (_celebrating) return;
    _celebrating = true;

    // Persist every milestone currently unlocked, not just the one being
    // celebrated: several can land on the same day, and the rest would
    // otherwise queue up one dialog per app open.
    final progress = ref.read(serviceProgressProvider);
    final soldier = ref.read(activeSoldierProvider);
    if (progress != null && soldier != null) {
      final unlocked =
          ref.read(computeMilestonesProvider).unlockedIds(progress);
      await ref
          .read(settingsControllerProvider.notifier)
          .markMilestonesUnlocked(soldier.id, unlocked);
    }

    // Marked whichever way the dialog was raised, so a milestone celebrated
    // as it happened is not shown again as the day's recap a few hours later.
    await _markRecapShown(milestone);

    if (!mounted) {
      _celebrating = false;
      return;
    }
    await showMilestoneCelebration(
      context,
      milestone,
      alreadyReached: alreadyReached,
    );
    _celebrating = false;
  }

  /// Identifies one showing: this milestone, for this soldier, today.
  /// Null when there is no active soldier to attribute it to.
  String? _recapTag(Milestone milestone) {
    final soldier = ref.read(activeSoldierProvider);
    if (soldier == null) return null;
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}'
        '|${soldier.id}|${milestone.id}';
  }

  Future<void> _markRecapShown(Milestone milestone) async {
    final tag = _recapTag(milestone);
    if (tag == null) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final today = tag.split('|').first;
    // Yesterday's entries are dropped on the way past, so the list stays the
    // size of one day's achievements rather than growing for the whole term.
    final kept = (prefs.getStringList(milestoneRecapShownKey) ?? const [])
        .where((e) => e.startsWith('$today|') && e != tag);
    await prefs.setStringList(milestoneRecapShownKey, [...kept, tag]);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Milestone?>(pendingCelebrationProvider, (previous, next) {
      if (next != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _celebrate(next);
        });
      }
    });

    // Re-schedule notifications when the active soldier or notification
    // settings change. A soldier just added — or switched to — also brings
    // its own achievements, including one that may fall on today, so the
    // day's milestone is re-checked for the new profile.
    ref.listen(activeSoldierProvider, (_, _) {
      _syncBackground();
      _maybeShowTodaysMilestone();
    });
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
