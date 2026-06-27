import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/l10n/app_strings.dart';
import '../shared/widgets/glass_card.dart';
import '../shared/widgets/gradient_scaffold.dart';
import '../shared/widgets/section_header.dart';

/// About + privacy screen.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    final version = snapshot.data?.version ?? '—';
                    return Text(
                      '${AppStrings.aboutVersionLabel}՝ $version',
                      style: theme.textTheme.bodySmall,
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
