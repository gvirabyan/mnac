import 'package:flutter/material.dart';

/// Instagram's camera glyph (rounded square, lens, flash dot) in the brand's
/// yellow-to-purple gradient, so the row reads as Instagram at a glance.
/// Material ships no brand icons, hence painting it.
class InstagramGlyph extends StatelessWidget {
  const InstagramGlyph({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _InstagramPainter(),
    );
  }
}

class _InstagramPainter extends CustomPainter {
  const _InstagramPainter();

  /// Instagram's brand gradient, bottom-left to top-right.
  static const _gradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [
      Color(0xFFFEDA75),
      Color(0xFFFA7E1E),
      Color(0xFFD62976),
      Color(0xFF962FBF),
      Color(0xFF4F5BD5),
    ],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    // Inset like a Material icon, which keeps its art inside a 20/24 frame.
    final frame = Rect.fromLTWH(s * 2 / 24, s * 2 / 24, s * 20 / 24, s * 20 / 24);
    final shader = _gradient.createShader(frame);
    final stroke = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 2 / 24;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        frame.deflate(stroke.strokeWidth / 2),
        Radius.circular(s * 5.5 / 24),
      ),
      stroke,
    );
    canvas.drawCircle(frame.center, s * 4.5 / 24, stroke);
    canvas.drawCircle(
      Offset(s * 17.3 / 24, s * 6.7 / 24),
      s * 1.3 / 24,
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_InstagramPainter old) => false;
}
