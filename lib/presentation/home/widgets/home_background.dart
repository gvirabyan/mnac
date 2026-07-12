import 'dart:io';

import 'package:flutter/material.dart';

/// Full-bleed home background.
///
/// If the user picked a custom background image it fills the screen (with a
/// readability scrim). Otherwise the bundled default photo
/// (assets/images/background.png) is shown with the same treatment.
class HomeBackground extends StatelessWidget {
  const HomeBackground({
    super.key,
    this.customImagePath,
    this.animate = true,
    this.scrimVisible = true,
  });

  static const String _defaultAsset = 'assets/images/background.png';

  final String? customImagePath;

  /// When true, the background image slowly pans and zooms (Ken Burns).
  final bool animate;

  /// When false, the readability scrim over the photo fades out so the clean
  /// image shows through (used by the immersive press-and-hold mode).
  final bool scrimVisible;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasCustomImage =
        customImagePath != null && File(customImagePath!).existsSync();
    final ImageProvider image = hasCustomImage
        ? FileImage(File(customImagePath!))
        : const AssetImage(_defaultAsset);

    return Stack(
      fit: StackFit.expand,
      children: [
        animate
            ? _KenBurnsImage(image: image)
            : Image(image: image, fit: BoxFit.cover),
        // Scrim to keep foreground text readable over any photo. It fades
        // away in immersive mode to reveal the clean image.
        AnimatedOpacity(
          opacity: scrimVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        Colors.black.withValues(alpha: 0.20),
                        Colors.black.withValues(alpha: 0.48),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.45),
                      ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A full-bleed image that slowly zooms and pans in a gentle, looping
/// "Ken Burns" motion to make the home backdrop feel alive.
class _KenBurnsImage extends StatefulWidget {
  const _KenBurnsImage({required this.image});

  final ImageProvider image;

  @override
  State<_KenBurnsImage> createState() => _KenBurnsImageState();
}

class _KenBurnsImageState extends State<_KenBurnsImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 28),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = Image(
      image: widget.image,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
    );

    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_controller.value);
          // Zoom 1.08x -> 1.22x while drifting the focal point diagonally so
          // the scaled-up (overflowing) image pans across the screen.
          final scale = 1.08 + 0.14 * t;
          final alignment = Alignment.lerp(
            const Alignment(-0.5, -0.35),
            const Alignment(0.5, 0.35),
            t,
          )!;
          return Transform.scale(
            scale: scale,
            alignment: alignment,
            child: child,
          );
        },
        child: image,
      ),
    );
  }
}
