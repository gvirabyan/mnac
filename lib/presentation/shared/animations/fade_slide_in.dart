import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_durations.dart';

/// A subtle entrance animation (fade + slight upward slide) used for decorative
/// polish. When [enabled] is false the child is returned untouched, so the
/// user's animation-level preference is respected (only the "full" level enables
/// these decorative entrances).
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.enabled = true,
    this.delay = Duration.zero,
  });

  final Widget child;
  final bool enabled;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return child
        .animate()
        .fadeIn(duration: AppDurations.medium, delay: delay)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }
}
