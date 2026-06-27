import 'package:flutter/material.dart';

/// Animates between integer values with a smooth tween, used for the live
/// countdown numbers. Honors [animate] to respect the user's animation level.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.animate = true,
    this.minDigits = 1,
  });

  final int value;
  final TextStyle? style;
  final bool animate;

  /// Pads the number with leading zeros to at least this many digits.
  final int minDigits;

  @override
  Widget build(BuildContext context) {
    if (!animate) {
      return Text(_format(value), style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: value.toDouble(), end: value.toDouble()),
      duration: const Duration(milliseconds: 350),
      builder: (context, v, _) => Text(_format(v.round()), style: style),
    );
  }

  String _format(int v) => v.toString().padLeft(minDigits, '0');
}
