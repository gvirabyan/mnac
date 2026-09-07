import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/l10n/app_strings.dart';
import '../shared/widgets/glass_card.dart';
import '../shared/widgets/gradient_scaffold.dart';
import '../../services/home_widget_service.dart';
import '../../services/push_service.dart';
import '../shared/widgets/section_header.dart';

/// About + privacy screen.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  /// Shows why push does or doesn't reach this device, and why the home
  /// widget is or isn't showing data, for diagnosing the two things that fail
  /// silently and out of sight. Deliberately unlabelled and behind a long
  /// press on the version line: it is a support tool, not a feature, and
  /// means nothing to a user who isn't being walked through it.
  Future<void> _showPushDiagnostics(BuildContext context, WidgetRef ref) async {
    final push = await ref.read(pushServiceProvider).diagnostics();
    final widget = await ref.read(homeWidgetServiceProvider).diagnostics();
    final report = widget.isEmpty ? push : '$push\n\n$widget';
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Diagnostics'),
        content: SingleChildScrollView(
          child: SelectableText(
            report,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: report));
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return GradientScaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsAbout)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          AppSizes.md,
          AppSizes.screenPadding,
          AppSizes.xxl,
        ),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.appName, style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSizes.xs),
                Text(AppStrings.aboutBody, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSizes.md),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    final version = info == null
                        ? '—'
                        : '${info.version} (${info.buildNumber})';
                    return GestureDetector(
                      onLongPress: () => _showPushDiagnostics(context, ref),
                      child: Text(
                        '${AppStrings.aboutVersionLabel}՝ $version',
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          const SectionHeader(title: AppStrings.settingsPrivacy),
          const SizedBox(height: AppSizes.md),
          GlassCard(
            child: Text(AppStrings.privacyBody, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
