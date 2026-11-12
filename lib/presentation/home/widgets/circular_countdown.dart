import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';

/// The home progress ring: a slim arc that fades in from its start and is
/// brightest at today, with a soft glow, over a quiet track tinted with the
/// same accent. Shows [child] in the middle. The arc animates toward
/// [percent].
class CircularCountdown extends StatelessWidget {
  const CircularCountdown({
    super.key,
    required this.percent,
    required this.child,
    this.size = AppSizes.countdownRingSize,
    this.stroke = AppSizes.countdownRingStroke,
    this.animate = true,
  });

  /// Completion fraction in 0..1.
  final double percent;
  final Widget child;
  final double size;
  final double stroke;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final track = theme.colorScheme.surfaceContainerHighest;

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: percent.clamp(0.0, 1.0)),
        duration: animate
            ? const Duration(milliseconds: 900)
            : Duration.zero,
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return CustomPaint(
            painter: _RingPainter(
              progress: value,
              accent: accent,
              track: track,
              stroke: stroke,
            ),
            child: Center(child: child),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.accent,
    required this.track,
    required this.stroke,
  });

  final double progress;
  final Color accent;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    // Room is left for the soft glow, which reaches past the stroke.
    final radius = (size.shortestSide - stroke) / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track: a quiet ring in the same hue as the arc, so the two belong
    // together instead of grey against colour.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Color.alphaBlend(accent.withValues(alpha: 0.10), track)
            .withValues(alpha: 0.55),
    );

    if (progress <= 0) return;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    // The round cap pokes out before the start; the gradient starts there
    // too, so the cap takes the faint tail colour rather than the bright one.
    final capAngle = (stroke / 2) / radius;
    final shader = SweepGradient(
      colors: [accent.withValues(alpha: 0.18), accent],
      stops: [0, ((sweepAngle + capAngle) / (2 * math.pi)).clamp(0.0, 1.0)],
      transform: GradientRotation(startAngle - capAngle),
    ).createShader(rect);

    // A soft glow under the arc.
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = shader
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // The arc: fades in from the start and is brightest at today.
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.accent != accent ||
      old.track != track ||
      old.stroke != stroke;
}
