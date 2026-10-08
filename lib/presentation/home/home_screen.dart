import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/router/app_router.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/utils/duration_breakdown.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/soldier_profile.dart';
import '../../services/image_storage_service.dart';
// AI cartoon, off for now — see _CartoonButton below.
// import '../../services/cartoon_avatar_service.dart';
// import '../cartoon/cartoon_screen.dart';
import '../announcements/announcements_screen.dart';
import '../milestones/milestones_screen.dart';
import '../shared/animations/fade_slide_in.dart';
import '../shared/state/announcements_provider.dart';
import '../shared/state/immersive_controller.dart';
import '../shared/state/settings_controller.dart';
import '../shared/state/soldiers_controller.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/glass_card.dart';
import '../share/share_card_screen.dart';
import '../soldier_form/soldier_form_screen.dart';
import '../soldiers/soldier_switcher_sheet.dart';
import 'home_controller.dart';
import 'widgets/breakdown_carousel.dart';
import 'widgets/circular_countdown.dart';
import 'widgets/unit_breakdown_row.dart';
import 'widgets/discharge_date_chip.dart';
import 'widgets/home_background.dart';
import 'widgets/quote_banner.dart';

/// Home tab: opens straight here (no onboarding). When there is no soldier yet
/// it invites the user to add one; otherwise it shows the live countdown over a
/// hero background.
///
/// Only the [_CountdownHero] and [_BreakdownCard] watch the per-second progress
/// provider (each isolated by a [RepaintBoundary]); the background, greeting,
/// chip and quote are built once per profile/settings change for smoothness.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeSoldierProvider);
    final animationLevel =
        ref.watch(settingsControllerProvider.select((s) => s.animationLevel));
    // Background = the active soldier's photo (same source as the avatar).
    final bgPath = profile?.photoPath;
    final soldierCount =
        ref.watch(soldiersControllerProvider.select((s) => s.soldiers.length));

    final animate = animationLevel != AnimationLevel.none;
    final decorate = animationLevel == AnimationLevel.full;
    final immersive = ref.watch(immersiveProvider);

    void setImmersive(bool value) =>
        ref.read(immersiveProvider.notifier).set(value);

    return Scaffold(
      backgroundColor: Colors.transparent,
      // Press-and-hold on an empty area hides all UI to reveal the background.
      body: GestureDetector(
        onLongPressStart: (_) => setImmersive(true),
        onLongPressEnd: (_) => setImmersive(false),
        onLongPressCancel: () => setImmersive(false),
        child: Stack(
          children: [
            Positioned.fill(
              child: HomeBackground(
                customImagePath: bgPath,
                animate: animate,
                scrimVisible: !immersive,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: immersive,
                // Plain Opacity (via TweenAnimationBuilder) instead of
                // AnimatedOpacity: at opacity 1.0 it skips the compositing
                // layer, so the glass cards' BackdropFilter stays clipped to
                // the cards and does NOT blur the whole background image.
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 1, end: immersive ? 0.0 : 1.0),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  builder: (context, value, child) =>
                      Opacity(opacity: value, child: child),
                  child: SafeArea(
                    child: profile == null
                        ? EmptyState(
                            icon: Icons.military_tech_outlined,
                            title: AppStrings.homeNoSoldierTitle,
                            subtitle: AppStrings.homeNoSoldierSubtitle,
                            actionLabel: AppStrings.homeAddSoldier,
                            onAction: () => Navigator.of(context).push(
                              appPageRoute(const SoldierFormScreen()),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(
                              AppSizes.screenPadding,
                              AppSizes.md,
                              AppSizes.screenPadding,
                              AppSizes.xxl,
                            ),
                            children: [
                              _TopBar(
                                profile: profile,
                                soldierCount: soldierCount,
                                onTap: () => showSoldierSwitcher(context),
                              ),
                              const SizedBox(height: AppSizes.xl),
                      _CountdownHero(animate: animate),
                      const SizedBox(height: AppSizes.xl),
                      FadeSlideIn(
                        enabled: decorate,
                        delay: const Duration(milliseconds: 100),
                        child: _BreakdownCard(animate: animate),
                      ),
                      const SizedBox(height: AppSizes.lg),
                      Center(
                        child: DischargeDateChip(
                          dischargeDate: profile.dischargeDate,
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            appPageRoute(const MilestonesScreen()),
                          ),
                          icon: const Icon(Icons.emoji_events_outlined),
                          label: const Text(AppStrings.milestonesTitle),
                        ),
                      ),
                      const SizedBox(height: AppSizes.xl),
                      QuoteBanner(animate: animate),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the push history; a dot marks announcements not yet seen there.
///
/// Watches only the newest announcement's time — one document read — never
/// the full history, since this button is on screen every time the app opens.
class _AnnouncementsButton extends ConsumerWidget {
  const _AnnouncementsButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnread = ref.watch(hasUnreadAnnouncementsProvider);
    return IconButton(
      tooltip: AppStrings.announcementsTitle,
      icon: Badge(
        isLabelVisible: hasUnread,
        smallSize: 8,
        child: const Icon(Icons.notifications_none_rounded),
      ),
      onPressed: () => Navigator.of(context).push(
        appPageRoute(const AnnouncementsScreen()),
      ),
    );
  }
}

/// Opens the share-card preview for the active soldier, capturing a progress
/// snapshot at tap time so the exported image is stable.
class _ShareButton extends ConsumerWidget {
  const _ShareButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: AppStrings.shareTitle,
      icon: const Icon(Icons.send_rounded),
      onPressed: () {
        final soldier = ref.read(activeSoldierProvider);
        final progress = ref.read(serviceProgressProvider);
        if (soldier == null || progress == null) return;
        Navigator.of(context).push(
          appPageRoute(
            ShareCardScreen(profile: soldier, progress: progress),
          ),
        );
      },
    );
  }
}

// AI cartoon portrait — switched off for now. This button is the feature's
// only entry point; CartoonScreen and CartoonAvatarService are intact. To
// bring it back, uncomment this class, its two imports at the top and its
// slot in the top row, and restore the cartoon line of
// AppStrings.privacyBody (the photo leaves the device again).
//
// /// Opens the cartoon-portrait screen; hidden in builds without an API key.
// class _CartoonButton extends ConsumerWidget {
//   const _CartoonButton();
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     if (!ref.watch(cartoonAvatarServiceProvider).isConfigured) {
//       return const SizedBox.shrink();
//     }
//     return IconButton(
//       tooltip: AppStrings.cartoonTitle,
//       icon: const Icon(Icons.auto_awesome_rounded),
//       onPressed: () => Navigator.of(context).push(
//         appPageRoute(const CartoonScreen()),
//       ),
//     );
//   }
// }

/// Picks a photo for the active soldier. Because the same `photoPath` is used
/// for both the avatar and the home background, this updates both at once.
class _BackgroundButton extends ConsumerWidget {
  const _BackgroundButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: AppStrings.onbChangePhoto,
      icon: const Icon(Icons.wallpaper_rounded),
      onPressed: () async {
        final soldier = ref.read(activeSoldierProvider);
        if (soldier == null) return;
        final picked = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 1600,
          imageQuality: 90,
        );
        if (picked == null) return;
        final path = await ref
            .read(imageStorageServiceProvider)
            .savePickedImage(picked.path, prefix: 'photo');
        await ref
            .read(soldiersControllerProvider.notifier)
            .addOrUpdate(soldier.copyWith(photoPath: path));
      },
    );
  }
}

/// Greeting plus the action buttons.
///
/// Avatar and buttons give way to the name: when it would not fit on one
/// line beside them at their normal size, both shrink a little — the avatar
/// and the buttons share the cut, so neither ends up tiny. A name too long
/// even then wraps to a second line and is cut with an ellipsis after that.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.profile,
    required this.soldierCount,
    required this.onTap,
  });

  final SoldierProfile profile;
  final int soldierCount;
  final VoidCallback onTap;

  static const List<Widget> _actions = [
    // _CartoonButton(), // AI cartoon, off for now
    _AnnouncementsButton(),
    _BackgroundButton(),
    _ShareButton(),
  ];

  /// Width of one action button at the default Material size.
  static const double _regularActionWidth = 48;

  /// Compact action button: 22px icon with 7px padding on each side (36px
  /// wide instead of 48).
  static const double _compactIconSize = 22;
  static const double _compactPadding = 7;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final nameRoom = constraints.maxWidth -
            _actions.length * _regularActionWidth -
            _Greeting.reservedWidth;
        final compact = !_Greeting.fitsOnOneLine(context, profile, nameRoom);

        final row = Row(
          children: [
            Expanded(
              child: _Greeting(
                profile: profile,
                soldierCount: soldierCount,
                onTap: onTap,
                compact: compact,
              ),
            ),
            ..._actions,
          ],
        );
        if (!compact) return row;

        return IconButtonTheme(
          data: IconButtonThemeData(
            style: IconButton.styleFrom(
              iconSize: _compactIconSize,
              padding: const EdgeInsets.all(_compactPadding),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          child: row,
        );
      },
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.profile,
    required this.soldierCount,
    required this.onTap,
    this.compact = false,
  });

  final SoldierProfile profile;
  final int soldierCount;
  final VoidCallback onTap;

  /// Smaller avatar and gap, to leave a long name more room.
  final bool compact;

  static const double _avatarRadius = 26;
  static const double _compactAvatarRadius = 21;
  static const double _chevronSize = 24;

  /// Horizontal space the greeting takes besides the name itself at the
  /// regular size: avatar, the gap after it, and the chevron.
  static const double reservedWidth =
      _avatarRadius * 2 + AppSizes.md + _chevronSize;

  static String _nameOf(SoldierProfile profile) =>
      profile.name ?? AppStrings.appName;

  static TextStyle? _nameStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge;

  /// Whether the name fits on a single line in [width] at the current text
  /// scale.
  static bool fitsOnOneLine(
    BuildContext context,
    SoldierProfile profile,
    double width,
  ) {
    if (width <= 0) return false;
    final painter = TextPainter(
      text: TextSpan(text: _nameOf(profile), style: _nameStyle(context)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout(maxWidth: width);
    final fits = !painter.didExceedMaxLines;
    painter.dispose();
    return fits;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto =
        profile.photoPath != null && File(profile.photoPath!).existsSync();
    final greeting = _nameOf(profile);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.xxs),
        child: Row(
          children: [
            Hero(
              tag: 'profile-photo',
              child: CircleAvatar(
                radius: compact ? _compactAvatarRadius : _avatarRadius,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                backgroundImage:
                    hasPhoto ? FileImage(File(profile.photoPath!)) : null,
                child: hasPhoto
                    ? null
                    : Icon(Icons.person_rounded,
                        color: theme.colorScheme.primary),
              ),
            ),
            SizedBox(width: compact ? AppSizes.sm : AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: _nameStyle(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (profile.unit != null)
                    Text(profile.unit!, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              soldierCount > 1
                  ? Icons.unfold_more_rounded
                  : Icons.expand_more_rounded,
              size: _chevronSize,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Watches the per-second progress in isolation.
class _CountdownHero extends ConsumerWidget {
  const _CountdownHero({required this.animate});
  final bool animate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(serviceProgressProvider);
    if (progress == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    // High-precision percent so the value visibly ticks every second.
    // toStringAsFixed handles rounding; split into integer + fractional parts
    // and render the fraction smaller for a clean, premium look.
    final pctText = (progress.percent * 100).toStringAsFixed(6); // "23.123456"
    final dot = pctText.indexOf('.');
    final intPart = pctText.substring(0, dot);
    final fracPart = pctText.substring(dot); // ".123456"
    const tabular = [FontFeature.tabularFigures()];

    return RepaintBoundary(
      child: Center(
        child: CircularCountdown(
          percent: progress.percent,
          animate: animate,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    intPart,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontFeatures: tabular,
                    ),
                  ),
                  Text(
                    '$fracPart%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary.withValues(alpha: 0.75),
                      fontFeatures: tabular,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.xxs),
              Text(
                progress.isComplete
                    ? AppStrings.homeCompleted
                    : AppStrings.homeUntilHome,
                style: theme.textTheme.labelMedium,
              ),
              if (!progress.isComplete && progress.hasStarted) ...[
                const SizedBox(height: AppSizes.xxs),
                Text(
                  AppStrings.homeDaysPassed(progress.daysServed),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary.withValues(alpha: 0.8),
                    fontFeatures: tabular,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Watches the per-second progress in isolation.
class _BreakdownCard extends ConsumerWidget {
  const _BreakdownCard({required this.animate});
  final bool animate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(serviceProgressProvider);
    if (progress == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    if (progress.isComplete) {
      return GlassCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
            child: Text(
              AppStrings.homeServiceDone,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: GlassCard(
        child: BreakdownCarousel(
          animateCounters: animate,
          autoScroll: animate,
          pages: [
            // Remaining time; tap cycles hierarchical → days → months.
            BreakdownPage(views: [
              BreakdownView.hierarchical(
                title: AppStrings.homeRemainingTitle,
                breakdown: progress.remaining,
              ),
              BreakdownView(
                title: AppStrings.homeRemainingDaysTitle,
                rows: _totalDaysRows(progress.end.difference(progress.now)),
              ),
              BreakdownView(
                title: AppStrings.homeRemainingWeeksTitle,
                rows: _totalWeeksRows(progress.end.difference(progress.now)),
              ),
              BreakdownView(
                title: AppStrings.homeRemainingMonthsTitle,
                rows: _totalMonthsRows(progress.remaining),
              ),
            ]),
            // Elapsed time; same tap cycle.
            BreakdownPage(views: [
              BreakdownView.hierarchical(
                title: AppStrings.homeElapsedTitle,
                breakdown: progress.elapsed,
              ),
              BreakdownView(
                title: AppStrings.homeElapsedDaysTitle,
                rows: _totalDaysRows(progress.now.difference(progress.start)),
              ),
              BreakdownView(
                title: AppStrings.homeElapsedWeeksTitle,
                rows: _totalWeeksRows(progress.now.difference(progress.start)),
              ),
              BreakdownView(
                title: AppStrings.homeElapsedMonthsTitle,
                rows: _totalMonthsRows(progress.elapsed),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  /// The whole span as total days ("525 days") over H / Min / Sec.
  static List<List<UnitValue>> _totalDaysRows(Duration d) => [
        [UnitValue(d.inDays, AppStrings.days)],
        [
          UnitValue(d.inHours % 24, AppStrings.hours, pad: true),
          UnitValue(d.inMinutes % 60, AppStrings.minutes, pad: true),
          UnitValue(d.inSeconds % 60, AppStrings.seconds, pad: true),
        ],
      ];

  /// The whole span as total weeks ("75 weeks 3 days") over H / Min / Sec.
  static List<List<UnitValue>> _totalWeeksRows(Duration d) => [
        [
          UnitValue(d.inDays ~/ 7, AppStrings.weeks),
          UnitValue(d.inDays % 7, AppStrings.days),
        ],
        [
          UnitValue(d.inHours % 24, AppStrings.hours, pad: true),
          UnitValue(d.inMinutes % 60, AppStrings.minutes, pad: true),
          UnitValue(d.inSeconds % 60, AppStrings.seconds, pad: true),
        ],
      ];

  /// The whole span as total months ("17 months 5 days") over H / Min / Sec.
  static List<List<UnitValue>> _totalMonthsRows(DurationBreakdown b) => [
        [
          UnitValue(b.years * 12 + b.months, AppStrings.months),
          UnitValue(b.weeks * 7 + b.days, AppStrings.days),
        ],
        [
          UnitValue(b.hours, AppStrings.hours, pad: true),
          UnitValue(b.minutes, AppStrings.minutes, pad: true),
          UnitValue(b.seconds, AppStrings.seconds, pad: true),
        ],
      ];
}
