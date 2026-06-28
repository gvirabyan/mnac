import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/service_progress.dart';
import '../../domain/entities/soldier_profile.dart';

/// A fixed-size, visually rich card summarizing a soldier's countdown, designed
/// to be captured to an image and shared.
///
/// Renders at a fixed logical size (a 4:5 portrait) so it can be captured at a
/// predictable resolution regardless of the device; the preview screen scales
/// it down with a [FittedBox].
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.profile,
    required this.progress,
  });

  final SoldierProfile profile;
  final ServiceProgress progress;

  /// Natural size used both for capture and for the preview's aspect ratio.
  static const Size size = Size(360, 450);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = progress.isComplete;
    final days = progress.daysRemaining < 0 ? 0 : progress.daysRemaining;
    final pct = progress.percentInt;
    final hasPhoto =
        profile.photoPath != null && File(profile.photoPath!).existsSync();

    const gold = AppColors.apricot;
    final onDark = AppColors.offWhite;
    final muted = AppColors.mutedDark;
    const tabular = [FontFeature.tabularFigures()];

    return SizedBox(
      width: size.width,
      height: size.height,
      child: ClipRRect(
        borderRadius:
            const BorderRadius.all(Radius.circular(AppSizes.radiusLg)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background: the soldier's photo (with a dark scrim so the light
            // text stays legible) when set, otherwise the branded gradient.
            if (hasPhoto) ...[
              Image.file(File(profile.photoPath!), fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x59000000), Color(0xD9000000)],
                  ),
                ),
              ),
            ] else
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.charcoal, AppColors.charcoalDeep],
                  ),
                ),
              ),
            // Soft apricot glow in the top-right for a premium feel.
            Positioned(
              top: -90,
              right: -90,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      gold.withValues(alpha: 0.30),
                      gold.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: avatar (or icon) + app name + percent chip.
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.cardDark,
                        backgroundImage: hasPhoto
                            ? FileImage(File(profile.photoPath!))
                            : null,
                        child: hasPhoto
                            ? null
                            : const Icon(Icons.military_tech_rounded,
                                color: gold, size: AppSizes.iconSm),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          profile.name ?? AppStrings.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: onDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm,
                          vertical: AppSizes.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: 0.18),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                        ),
                        child: Text(
                          '$pct%',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: gold,
                            fontFeatures: tabular,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Hero: big remaining-days number, or a completion title.
                  if (isDone)
                    Text(
                      AppStrings.shareCompletedTitle,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: gold,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    )
                  else ...[
                    Text(
                      '$days',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: onDark,
                        fontWeight: FontWeight.w800,
                        fontFeatures: tabular,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xxs),
                    Text(
                      AppStrings.shareDaysSuffix,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSizes.lg),
                  // Progress bar.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    child: LinearProgressIndicator(
                      value: progress.percent.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: AppColors.cardDark,
                      valueColor: const AlwaysStoppedAnimation<Color>(gold),
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  // Discharge date.
                  Row(
                    children: [
                      const Icon(Icons.flag_rounded,
                          color: gold, size: AppSizes.iconSm),
                      const SizedBox(width: AppSizes.xs),
                      Text(
                        '${AppStrings.shareDischargeLabel}՝ '
                        '${AppDateUtils.formatLong(profile.dischargeDate)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: onDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  const Divider(color: AppColors.outlineDark, height: 1),
                  const SizedBox(height: AppSizes.sm),
                  // Footer: app name + tagline.
                  Row(
                    children: [
                      Text(
                        AppStrings.appName,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: gold,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        AppStrings.appTagline,
                        style: theme.textTheme.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
