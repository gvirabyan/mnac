import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router/app_router.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/di/providers.dart';
import '../../core/l10n/app_strings.dart';
import '../../domain/entities/app_settings.dart';
import '../../services/notification_service.dart';
import '../shared/state/settings_controller.dart';
import '../shared/state/soldiers_controller.dart';
import '../shared/widgets/glass_card.dart';
import '../shared/widgets/gradient_scaffold.dart';
import 'about_screen.dart';
import 'widgets/option_segments.dart';
import 'widgets/settings_tile.dart';

/// Settings tab: theme, notifications, local backup/restore/reset,
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
        // Extra bottom inset so the last tile scrolls clear of the floating
        // glass nav bar (the shell uses extendBody: true).
        padding: EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          AppSizes.md,
          AppSizes.screenPadding,
          AppSizes.xxl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          const _ThemeGroup(),
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

/// Theme picker, inlined here rather than behind a personalization screen:
/// it is the only app-level visual preference, so a whole sub-page for one
/// control was more navigation than it was worth.
class _ThemeGroup extends ConsumerWidget {
  const _ThemeGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mode =
        ref.watch(settingsControllerProvider.select((s) => s.themeMode));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined,
                  color: theme.colorScheme.primary, size: AppSizes.iconMd),
              const SizedBox(width: AppSizes.md),
              Text(AppStrings.persTheme, style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          OptionSegments<AppThemeMode>(
            selected: mode,
            onChanged:
                ref.read(settingsControllerProvider.notifier).setThemeMode,
            options: const [
              SegmentOption(AppThemeMode.system, AppStrings.persThemeSystem),
              SegmentOption(AppThemeMode.light, AppStrings.persThemeLight),
              SegmentOption(AppThemeMode.dark, AppStrings.persThemeDark),
            ],
          ),
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

/// Notifications: a single master toggle, no sub-options.
///
/// Turning it on asks the OS for permission first and only records the setting
/// once permission is actually granted — otherwise the switch would sit in the
/// "on" position while the OS silently blocks every notification. Because the
/// switch renders straight off the stored setting, refusing the prompt leaves
/// it visibly off. Changes are picked up by the sync listener in [MainShell],
/// which re-schedules the daily reminder and milestone alerts.
class _NotificationsGroup extends ConsumerWidget {
  const _NotificationsGroup();

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    final notifier = ref.read(settingsControllerProvider.notifier);
    if (!value) {
      await notifier.setNotificationsEnabled(false);
      return;
    }

    final granted =
        await ref.read(notificationServiceProvider).requestPermissions();
    if (!granted) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.notifPermissionDenied)),
        );
      return;
    }

    // The daily reminder is the point of the toggle, so it comes on with it
    // rather than hiding behind a second switch.
    await notifier.update(
      (s) => s.copyWith(notificationsEnabled: true, dailyReminderEnabled: true),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      settingsControllerProvider.select((s) => s.notificationsEnabled),
    );

    return GlassCard(
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        secondary: Icon(
          Icons.notifications_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text(AppStrings.notifEnable),
        value: enabled,
        onChanged: (v) => _toggle(context, ref, v),
      ),
    );
  }
}
