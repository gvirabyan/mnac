import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_sizes.dart';
import '../home_controller.dart';
import 'glow_pulse.dart';

/// Shows the motivational Armenian "quote of the day".
///
/// The quote is chosen deterministically from the calendar day, so it stays the
/// same all day and gently fades to the next one at midnight (see
/// [quoteOfTheDayProvider]).
class QuoteBanner extends ConsumerWidget {
  const QuoteBanner({super.key, this.animate = true});

  final bool animate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final quote = ref.watch(quoteOfTheDayProvider);
    if (quote == null) {
      return const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: animate ? AppDurations.medium : Duration.zero,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      // A thin neutral frame that hugs the text, over a faint shade that
      // keeps it readable on any photo, with a faint gold glow around it
      // that breathes with the other glows on Home.
      child: Center(
        key: ValueKey(quote),
        child: RepaintBoundary(
         child: AnimatedBuilder(
          animation: GlowPulse.of(context),
          builder: (context, text) => Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(
                  alpha: 0.03 + 0.08 * GlowPulse.of(context).value,
                ),
                blurRadius: 24,
                spreadRadius: -4,
              ),
            ],
          ),
          child: text,
          ),
          child: Text(
            '«$quote»',
            textAlign: TextAlign.center,
            // Upright and regular: italics render poorly in Armenian, and
            // the text reads as a quiet line rather than a slogan.
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              height: 1.45,
            ),
          ),
         ),
        ),
      ),
    );
  }
}
