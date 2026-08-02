import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/service_progress.dart';
import '../../domain/entities/soldier_profile.dart';

/// A full-bleed 9:16 story canvas summarizing a soldier's countdown, designed
/// to be captured to an image and posted straight to Instagram/WhatsApp
/// stories.
///
/// Renders at a fixed logical size so the capture resolution is predictable
/// regardless of device; the preview screen scales it down with a [FittedBox].
/// Deliberately full-bleed with no rounded corners — a story fills the screen,
/// so any card framing would just read as a letterboxed screenshot.
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.profile,
    required this.progress,
  });

  final SoldierProfile profile;
  final ServiceProgress progress;

  /// Natural size used both for capture and for the preview's aspect ratio.
  /// 9:16, so the default 3.0 capture ratio lands on exactly 1080x1920 — the
  /// native story resolution, with no upscaling or letterboxing.
  static const Size size = Size(360, 640);

  /// Story apps overlay their own chrome (avatar and caption at the top, the
  /// reply bar at the bottom). Everything meaningful stays inside these insets.
  static const EdgeInsets _safeArea = EdgeInsets.fromLTRB(36, 92, 36, 116);

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
    const tabular = [FontFeature.tabularFigures()];

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background: the soldier's photo (with a scrim heavy enough at both
          // ends to keep the header and footer legible over any photo) when
          // set, otherwise the branded gradient.
          if (hasPhoto) ...[
            Image.file(File(profile.photoPath!), fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xCC000000),
                    Color(0x73000000),
                    Color(0xE6000000),
                  ],
                  stops: [0, 0.42, 1],
                ),
              ),
            ),
          ] else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF241F17),
                    AppColors.charcoal,
                    AppColors.charcoalDeep,
                  ],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
          // Apricot bloom behind the hero number, echoing the splash screen.
          const _Glow(
            alignment: Alignment(0.85, -0.55),
            diameter: 420,
            opacity: 0.28,
          ),
          const _Glow(
            alignment: Alignment(-0.9, 0.35),
            diameter: 320,
            opacity: 0.12,
          ),
          Padding(
            padding: _safeArea,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  name: profile.name ?? AppStrings.appName,
                  photoPath: hasPhoto ? profile.photoPath : null,
                  percent: pct,
                ),
                const Spacer(flex: 3),
                // Hero: the number is the whole point, so it gets the room.
                if (isDone)
                  Text(
                    AppStrings.shareCompletedTitle,
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 58,
                      color: gold,
                      fontWeight: FontWeight.w700,
                      height: 1.08,
                    ),
                  )
                else ...[
                  Text(
                    AppStrings.homeRemainingTitle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 15,
                      color: gold,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 5,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  // Scales down rather than overflowing: a custom service
                  // length can push the count past three digits.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$days',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 46,
                        color: onDark,
                        fontWeight: FontWeight.w800,
                        fontFeatures: tabular,
                        height: 0.92,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    AppStrings.shareDaysSuffix,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 24,
                      color: onDark.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const Spacer(flex: 2),
                _ProgressBar(value: progress.percent),
                const SizedBox(height: AppSizes.md),
                Row(
                  children: [
                    const Icon(Icons.flag_rounded,
                        color: gold, size: AppSizes.iconSm),
                    const SizedBox(width: AppSizes.xs),
                    Text(
                      '${AppStrings.shareDischargeLabel}՝ '
                      '${AppDateUtils.formatLong(profile.dischargeDate)}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        color: onDark.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Footer branding: the same wordmark the splash uses, so a
                // reshared story is recognisably from this app.
                const _Footer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft radial apricot bloom used to give the flat background some depth.
class _Glow extends StatelessWidget {
  const _Glow({
    required this.alignment,
    required this.diameter,
    required this.opacity,
  });

  final Alignment alignment;
  final double diameter;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.apricot.withValues(alpha: opacity),
                AppColors.apricot.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.photoPath,
    required this.percent,
  });

  final String name;
  final String? photoPath;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.cardDark,
          backgroundImage: photoPath != null ? FileImage(File(photoPath!)) : null,
          child: photoPath != null
              ? null
              : const Icon(Icons.military_tech_rounded,
                  color: AppColors.apricot, size: AppSizes.iconMd),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 19,
              color: AppColors.offWhite,
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
            color: AppColors.apricot.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            border: Border.all(
              color: AppColors.apricot.withValues(alpha: 0.45),
            ),
          ),
          child: Text(
            '$percent%',
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 15,
              color: AppColors.apricot,
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      child: SizedBox(
        height: 10,
        child: Stack(
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(color: Color(0x40FFFFFF)),
              child: SizedBox.expand(),
            ),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFD37A), AppColors.apricot],
                  ),
                ),
                child: SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: AppColors.offWhite.withValues(alpha: 0.15)),
        const SizedBox(height: AppSizes.md),
        Row(
          children: [
            SvgPicture.asset(
              'assets/svg/splash_wordmark.svg',
              width: 86,
              semanticsLabel: AppStrings.appName,
            ),
            const Spacer(),
            Text(
              AppStrings.appTagline,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: AppColors.offWhite.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
