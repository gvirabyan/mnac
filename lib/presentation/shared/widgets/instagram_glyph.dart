import 'package:flutter/material.dart';

/// Instagram's camera glyph (rounded square, lens, flash dot), drawn in a
/// single colour so it sits beside the app's Material icons like one of them.
/// Material ships no brand icons, hence painting it.
class InstagramGlyph extends StatelessWidget {
  const InstagramGlyph({super.key, required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _InstagramPainter(color),
    );
  }
}

class _InstagramPainter extends CustomPainter {
  _InstagramPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    // Inset like a Material icon, which keeps its art inside a 20/24 frame.
    final frame = Rect.fromLTWH(s * 2 / 24, s * 2 / 24, s * 20 / 24, s * 20 / 24);
    final stroke = Paint()
      ..color = color
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
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_InstagramPainter old) => old.color != color;
}
