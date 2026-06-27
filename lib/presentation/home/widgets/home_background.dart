import 'dart:io';

import 'package:flutter/material.dart';

/// Full-bleed home background.
///
/// If the user picked a custom background image it fills the screen (with a
/// readability scrim). Otherwise a hand-painted Mount Ararat scene is drawn —
/// a premium, distinctly Armenian backdrop reminiscent of a hero photo, with
/// no bundled asset required.
class HomeBackground extends StatelessWidget {
  const HomeBackground({super.key, this.customImagePath});

  final String? customImagePath;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final hasImage = customImagePath != null &&
        File(customImagePath!).existsSync();

    if (hasImage) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(customImagePath!), fit: BoxFit.cover),
          // Scrim to keep foreground text readable over any photo.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.70),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.30),
                        Colors.white.withValues(alpha: 0.75),
                      ],
              ),
            ),
          ),
        ],
      );
    }

    return CustomPaint(
      painter: _AraratPainter(isDark: isDark, accent: accent),
      size: Size.infinite,
    );
  }
}

class _AraratPainter extends CustomPainter {
  _AraratPainter({required this.isDark, required this.accent});

  final bool isDark;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sky gradient.
    final sky = isDark
        ? const [Color(0xFF1B2438), Color(0xFF232B3C), Color(0xFF14110D)]
        : const [Color(0xFFFCEFD8), Color(0xFFF7E3C2), Color(0xFFF4ECE1)];
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: sky,
        ).createShader(Offset.zero & size),
    );

    // Sun / moon glow.
    final glowCenter = Offset(w * 0.72, h * 0.20);
    canvas.drawCircle(
      glowCenter,
      h * 0.16,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: isDark ? 0.45 : 0.55),
            accent.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: h * 0.16)),
    );

    // Far mountain range.
    final backColor = isDark ? const Color(0xFF2A3346) : const Color(0xFFE7CBA2);
    final back = Path()
      ..moveTo(0, h * 0.62)
      ..lineTo(w * 0.18, h * 0.50)
      ..lineTo(w * 0.34, h * 0.60)
      ..lineTo(w * 0.55, h * 0.46)
      ..lineTo(w * 0.78, h * 0.58)
      ..lineTo(w, h * 0.50)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(back, Paint()..color = backColor);

    // Mount Ararat — greater (left) and lesser (right) peaks.
    final araratColor =
        isDark ? const Color(0xFF3B4660) : const Color(0xFF93A4B8);
    final greaterApex = Offset(w * 0.40, h * 0.40);
    final lesserApex = Offset(w * 0.70, h * 0.55);

    final ararat = Path()
      ..moveTo(-w * 0.05, h)
      ..lineTo(greaterApex.dx, greaterApex.dy)
      ..lineTo(w * 0.55, h * 0.74)
      ..lineTo(lesserApex.dx, lesserApex.dy)
      ..lineTo(w * 1.05, h)
      ..close();
    canvas.drawPath(ararat, Paint()..color = araratColor);

    // Snow caps.
    final snow = Paint()..color = const Color(0xFFF5F7FA);
    canvas.drawPath(_snowCap(greaterApex, w * 0.075, h * 0.075), snow);
    canvas.drawPath(_snowCap(lesserApex, w * 0.055, h * 0.055), snow);

    // Foreground hill band.
    final foreColor =
        isDark ? const Color(0xFF0E0B08) : const Color(0xFFD8C29B);
    final fore = Path()
      ..moveTo(0, h * 0.86)
      ..quadraticBezierTo(w * 0.30, h * 0.80, w * 0.55, h * 0.87)
      ..quadraticBezierTo(w * 0.80, h * 0.93, w, h * 0.86)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(fore, Paint()..color = foreColor);

    // Bottom scrim for content readability.
    canvas.drawRect(
      Rect.fromLTRB(0, h * 0.55, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [Colors.transparent, Colors.black.withValues(alpha: 0.45)]
              : [Colors.transparent, Colors.white.withValues(alpha: 0.55)],
        ).createShader(Rect.fromLTRB(0, h * 0.55, w, h)),
    );
  }

  /// A small jagged snow cap centered on a peak apex.
  Path _snowCap(Offset apex, double halfWidth, double height) {
    return Path()
      ..moveTo(apex.dx - halfWidth, apex.dy + height)
      ..lineTo(apex.dx - halfWidth * 0.4, apex.dy + height * 0.35)
      ..lineTo(apex.dx - halfWidth * 0.1, apex.dy + height * 0.75)
      ..lineTo(apex.dx + halfWidth * 0.25, apex.dy + height * 0.30)
      ..lineTo(apex.dx + halfWidth * 0.6, apex.dy + height * 0.7)
      ..lineTo(apex.dx + halfWidth, apex.dy + height)
      ..lineTo(apex.dx, apex.dy)
      ..close();
  }

  @override
  bool shouldRepaint(_AraratPainter old) =>
      old.isDark != isDark || old.accent != accent;
}
