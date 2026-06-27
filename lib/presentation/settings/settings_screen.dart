import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router/app_router.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/di/providers.dart';
import '../../core/l10n/app_strings.dart';
import '../../services/notification_service.dart';
import '../shared/state/settings_controller.dart';
import '../shared/state/soldiers_controller.dart';
import '../shared/widgets/glass_card.dart';
import '../shared/widgets/gradient_scaffold.dart';
import 'about_screen.dart';
import 'personalization_screen.dart';
import 'widgets/settings_tile.dart';

/// Settings tab: profile editing, personalization, local backup/restore/reset,
/// privacy/about, and feedback.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(appPageRoute(screen));
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(backupDataProvider)();
    if (!context.mounted) return;
    await result.fold(
      (path) async {
        _snack(context, AppStrings.backupDone);
        await SharePlus.instance.share(
          ShareParams(files: [XFile(path)], subject: AppStrings.appName),
        );
      },
      (_) async => _snack(context, AppStrings.errorGeneric),
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(restoreDataProvider)();
    if (!context.mounted) return;
    await result.fold(
      (restored) async {
        if (!restored) return; // no backup file present
        await ref.read(soldiersControllerProvider.notifier).reload();
        await ref.read(settingsControllerProvider.notifier).reload();
        if (context.mounted) _snack(context, AppStrings.restoreDone);
      },
      (_) async => _snack(context, AppStrings.restoreFailed),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.resetConfirmTitle),
        content: const Text(AppStrings.resetConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(settingsControllerProvider.notifier).resetToDefaults();
    await ref.read(soldiersControllerProvider.notifier).clearAll();
    // RootGate switches to onboarding automatically.
  }

  Future<void> _feedback() async {
    final uri = Uri(
      scheme: 'mailto',
      query: 'subject=${Uri.encodeComponent('${AppStrings.appName} — ${AppStrings.settingsFeedback}')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GradientScaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          AppSizes.md,
          AppSizes.screenPadding,
          AppSizes.xxl,
        ),
        children: [
          _Group(children: [
            SettingsTile(
              icon: Icons.palette_outlined,
              title: AppStrings.settingsPersonalization,
              onTap: () => _push(context, const PersonalizationScreen()),
              trailing: const _Chevron(),
            ),
          ]),
          const SizedBox(height: AppSizes.lg),
          const _NotificationsGroup(),
          const SizedBox(height: AppSizes.lg),
          _Group(children: [
            SettingsTile(
              icon: Icons.backup_outlined,
              title: AppStrings.settingsBackup,
              onTap: () => _backup(context, ref),
            ),
            const _Divider(),
            SettingsTile(
              icon: Icons.restore_outlined,
              title: AppStrings.settingsRestore,
              onTap: () => _restore(context, ref),
            ),
            const _Divider(),
            SettingsTile(
              icon: Icons.delete_forever_outlined,
              title: AppStrings.settingsReset,
              destructive: true,
              onTap: () => _confirmReset(context, ref),
            ),
          ]),
          const SizedBox(height: AppSizes.lg),
          _Group(children: [
            SettingsTile(
              icon: Icons.info_outline_rounded,
              title: AppStrings.settingsAbout,
              onTap: () => _push(context, const AboutScreen()),
              trailing: const _Chevron(),
            ),
            const _Divider(),
            SettingsTile(
              icon: Icons.mail_outline_rounded,
              title: AppStrings.settingsFeedback,
              onTap: _feedback,
            ),
          ]),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: AppSizes.md,
      endIndent: AppSizes.md,
      color: Theme.of(context).colorScheme.outline,
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.chevron_right_rounded,
        color: Theme.of(context).colorScheme.outline);
  }
}

/// Notification preferences: master toggle, daily inactivity reminder (with
/// time), and milestone alerts. Changes are picked up by the sync listener in
/// [MainShell], which re-schedules notifications.
class _NotificationsGroup extends ConsumerWidget {
  const _NotificationsGroup();

  static String _formatTime(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _toggleMaster(WidgetRef ref, bool value) async {
    final notifier = ref.read(settingsControllerProvider.notifier);
    if (value) {
      await ref.read(notificationServiceProvider).requestPermissions();
      // Turn the daily 19:00 reminder on by default when notifications are
      // enabled, so the headline reminder works without a second toggle.
      await notifier.update(
        (s) => s.copyWith(notificationsEnabled: true, dailyReminderEnabled: true),
      );
    } else {
      await notifier.setNotificationsEnabled(false);
    }
  }

  Future<void> _pickTime(
      BuildContext context, WidgetRef ref, int current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked != null) {
      await ref
          .read(settingsControllerProvider.notifier)
          .setDailyReminderMinutes(picked.hour * 60 + picked.minute);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final ctrl = ref.read(settingsControllerProvider.notifier);
    final accent = theme.colorScheme.primary;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SwitchListTile(
            secondary:
                Icon(Icons.notifications_outlined, color: accent),
            title: const Text(AppStrings.notifEnable),
            value: settings.notificationsEnabled,
            onChanged: (v) => _toggleMaster(ref, v),
          ),
          if (settings.notificationsEnabled) ...[
            const _Divider(),
            SwitchListTile(
              secondary: Icon(Icons.alarm_outlined, color: accent),
              title: const Text(AppStrings.notifDailyReminder),
              subtitle: const Text(AppStrings.notifDailyReminderDesc),
              isThreeLine: true,
              value: settings.dailyReminderEnabled,
              onChanged: ctrl.setDailyReminderEnabled,
            ),
            if (settings.dailyReminderEnabled)
              SettingsTile(
                icon: Icons.schedule_rounded,
                title: AppStrings.notifReminderTime,
                onTap: () =>
                    _pickTime(context, ref, settings.dailyReminderMinutes),
                trailing: Text(
                  _formatTime(settings.dailyReminderMinutes),
                  style: theme.textTheme.titleMedium?.copyWith(color: accent),
                ),
              ),
            const _Divider(),
            SwitchListTile(
              secondary: Icon(Icons.emoji_events_outlined, color: accent),
              title: const Text(AppStrings.notifMilestones),
              value: settings.milestoneNotificationsEnabled,
              onChanged: ctrl.setMilestoneNotifications,
            ),
            const _Divider(),
            SettingsTile(
              icon: Icons.notification_add_outlined,
              title: AppStrings.notifTest,
              onTap: () => _sendTest(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _sendTest(BuildContext context, WidgetRef ref) async {
    final service = ref.read(notificationServiceProvider);
    final granted = await service.requestPermissions();
    if (!context.mounted) return;
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.notifPermissionDenied)),
      );
      return;
    }
    await service.showTest();
  }
}
