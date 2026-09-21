import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/app_router.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/milestone.dart';
import '../home/home_controller.dart';
import '../share/share_card_screen.dart';
import '../shared/state/soldiers_controller.dart';
import '../shared/widgets/primary_button.dart';

/// Shows the milestone dialog with confetti and haptics.
///
/// Set [alreadyReached] for a milestone the user reached earlier today rather
/// than in this very moment: the same dialog, opened quietly — the day's
/// achievement is worth showing again on the next app open, but it is no
/// longer news.
Future<void> showMilestoneCelebration(
  BuildContext context,
  Milestone milestone, {
  bool alreadyReached = false,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _MilestoneCelebration(
      milestone: milestone,
      alreadyReached: alreadyReached,
    ),
  );
}

class _MilestoneCelebration extends ConsumerStatefulWidget {
  const _MilestoneCelebration({
    required this.milestone,
    required this.alreadyReached,
  });

  final Milestone milestone;
  final bool alreadyReached;

  @override
  ConsumerState<_MilestoneCelebration> createState() =>
      _MilestoneCelebrationState();
}

class _MilestoneCelebrationState extends ConsumerState<_MilestoneCelebration> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    // Confetti and a jolt in the hand are for the moment it happens. A recap
    // of something already reached today opens without either.
    if (!widget.alreadyReached) {
      _confetti.play();
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  /// Opens the share-card preview with this milestone printed on the card,
  /// over the soldier's own photo where one is set.
  void _share() {
    final profile = ref.read(activeSoldierProvider);
    final progress = ref.read(serviceProgressProvider);
    if (profile == null || progress == null) return;

    // Replaces the dialog rather than stacking the preview on top of it:
    // returning from the share sheet to a dialog about a milestone just
    // shared reads as the app having lost its place.
    Navigator.of(context)
      ..pop()
      ..push(
        appPageRoute(
          ShareCardScreen(
            profile: profile,
            progress: progress,
            milestone: widget.milestone,
          ),
        ),
      );
  }

  /// The milestone in a few characters, as on its card in the list.
  String get _badge => switch (widget.milestone.kind) {
        MilestoneKind.percent => '${widget.milestone.value}%',
        MilestoneKind.daysServed =>
          '${widget.milestone.value} ${AppStrings.milestoneUnitDays}',
        MilestoneKind.daysRemaining =>
          '${AppStrings.milestoneUnitLeft} ${widget.milestone.value}',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirection: math.pi / 2,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            maxBlastForce: 24,
            minBlastForce: 8,
            gravity: 0.25,
            colors: const [
              Color(0xFFF2A900),
              Color(0xFFD90012),
              Color(0xFF0033A0),
              Colors.white,
            ],
          ),
        ),
        Center(
          child: Dialog(
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            // Scrollable so the dialog still fits on a short screen at the
            // largest font scale the app offers, instead of overflowing.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The trophy sits in an accent halo so it reads as an
                  // emblem rather than a loose icon on the surface.
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(alpha: 0.22),
                          accent.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.emoji_events_rounded,
                      size: 72,
                      color: accent,
                    )
                        .animate()
                        .scale(duration: 500.ms, curve: Curves.elasticOut)
                        .then()
                        .shimmer(duration: 1200.ms),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    widget.alreadyReached
                        ? AppStrings.milestoneReachedToday
                        : AppStrings.milestoneReached,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    AppStrings.milestoneTitle(widget.milestone.id),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    AppStrings.milestoneMessage(widget.milestone.id),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Wrap(
                    spacing: AppSizes.xs,
                    runSpacing: AppSizes.xs,
                    alignment: WrapAlignment.center,
                    children: [
                      _Chip(
                        icon: Icons.military_tech_rounded,
                        label: _badge,
                        filled: true,
                      ),
                      _Chip(
                        icon: Icons.event_available_rounded,
                        label: AppDateUtils.formatLong(
                          widget.milestone.estimatedDate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xl),
                  PrimaryButton(
                    label: AppStrings.milestoneShare,
                    icon: Icons.ios_share_rounded,
                    onPressed: _share,
                  ),
                  const SizedBox(height: AppSizes.xxs),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(AppStrings.milestoneClose),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A small pill carrying one fact about the milestone: what it counts, and
/// the day it fell on.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final foreground = filled ? accent : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xxs,
      ),
      decoration: BoxDecoration(
        color: filled
            ? accent.withValues(alpha: 0.14)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border:
            filled ? Border.all(color: accent.withValues(alpha: 0.4)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: foreground),
          const SizedBox(width: AppSizes.xxs),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
