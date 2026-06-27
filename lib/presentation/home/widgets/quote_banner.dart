import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_durations.dart';
import '../home_controller.dart';

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
    final quote = ref.watch(quoteOfTheDayProvider);
    if (quote == null) {
      return const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: animate ? AppDurations.medium : Duration.zero,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: Text(
        '«$quote»',
        key: ValueKey(quote),
        textAlign: TextAlign.center,
        style: theme.textTheme.titleMedium?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          height: 1.4,
        ),
      ),
    );
  }
}
