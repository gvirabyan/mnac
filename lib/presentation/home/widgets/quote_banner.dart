import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_durations.dart';
import '../home_controller.dart';

/// Shows a rotating motivational Armenian quote with a gentle fade transition.
class QuoteBanner extends ConsumerStatefulWidget {
  const QuoteBanner({super.key, this.animate = true});

  final bool animate;

  @override
  ConsumerState<QuoteBanner> createState() => _QuoteBannerState();
}

class _QuoteBannerState extends ConsumerState<QuoteBanner> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _timer = Timer.periodic(AppDurations.quoteRotation, (_) {
        if (!mounted) return;
        final quotes = ref.read(quotesProvider).value;
        if (quotes == null || quotes.isEmpty) return;
        setState(() => _index = (_index + 1) % quotes.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quotes = ref.watch(quotesProvider).value;
    if (quotes == null || quotes.isEmpty) {
      return const SizedBox.shrink();
    }
    final quote = quotes[_index % quotes.length];

    return AnimatedSwitcher(
      duration: AppDurations.medium,
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
