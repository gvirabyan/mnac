import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/l10n/app_strings.dart';

/// Shows a celebratory milestone dialog with confetti and haptics.
Future<void> showMilestoneCelebration(
  BuildContext context,
  int threshold,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _MilestoneCelebration(threshold: threshold),
  );
}

class _MilestoneCelebration extends StatefulWidget {
  const _MilestoneCelebration({required this.threshold});
  final int threshold;

  @override
  State<_MilestoneCelebration> createState() => _MilestoneCelebrationState();
}

class _MilestoneCelebrationState extends State<_MilestoneCelebration> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    _confetti.play();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 72,
                    color: theme.colorScheme.primary,
                  )
                      .animate()
                      .scale(duration: 500.ms, curve: Curves.elasticOut)
                      .then()
                      .shimmer(duration: 1200.ms),
                  const SizedBox(height: AppSizes.lg),
                  Text(
                    '${widget.threshold}% — ${AppStrings.milestoneTitle(widget.threshold)}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    AppStrings.milestoneMessage(widget.threshold),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(AppStrings.milestoneClose),
                    ),
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
