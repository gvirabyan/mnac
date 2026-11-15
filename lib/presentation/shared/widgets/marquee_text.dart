import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One line of text that scrolls sideways, like a ticker, when it is too
/// long for its space; text that fits stays still.
///
/// Waits a moment at the start of each pass, then runs left at a steady
/// pace with a second copy following, so the line loops without a jump.
/// With animations turned off in the system settings it is a plain line
/// cut short with an ellipsis.
class MarqueeText extends StatefulWidget {
  const MarqueeText(this.text, {super.key, this.style});

  final InlineSpan text;
  final TextStyle? style;

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  /// Logical pixels per second.
  static const double _speed = 30;

  /// The gap between the end of the text and its next copy.
  static const double _gap = 40;

  /// The still moment at the start of each pass.
  static const Duration _pause = Duration(milliseconds: 1800);

  late final AnimationController _controller = AnimationController(
    vsync: this,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    final textScaler = MediaQuery.textScalerOf(context);
    final still = MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(style: style, children: [widget.text]),
          textDirection: Directionality.of(context),
          textScaler: textScaler,
          maxLines: 1,
        )..layout();
        final textWidth = painter.width;
        painter.dispose();

        if (still || textWidth <= constraints.maxWidth) {
          if (_controller.isAnimating) _controller.stop();
          return Text.rich(
            widget.text,
            style: widget.style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        final distance = textWidth + _gap;
        final runMs = distance / _speed * 1000;
        final pass = _pause + Duration(milliseconds: runMs.round());
        if (_controller.duration != pass || !_controller.isAnimating) {
          _controller
            ..duration = pass
            ..repeat();
        }
        final pauseShare = _pause.inMilliseconds / pass.inMilliseconds;

        final line = Text.rich(
          widget.text,
          style: widget.style,
          maxLines: 1,
          softWrap: false,
        );
        return ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;
              final run = t <= pauseShare
                  ? 0.0
                  : (t - pauseShare) / (1 - pauseShare);
              return OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: 0,
                maxWidth: double.infinity,
                child: Transform.translate(
                  offset: Offset(-math.min(run, 1.0) * distance, 0),
                  child: child,
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [line, const SizedBox(width: _gap), line],
            ),
          ),
        );
      },
    );
  }
}
