import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// The logo dove, at its full size throughout, flying in from beyond the left
/// edge of the screen along a gentle arc, beating its wings, and landing on
/// its resting spot in the centre, where it becomes the logo. [FlyingLogo]
/// must therefore sit horizontally centred on the screen.
///
/// The logo is one flat raster, so the flight uses layers cut from it by
/// `tool/split_logo_wing.py`: the body, and the wing, which swings about the
/// shoulder — up, through level, to below the body — while the body bobs
/// against it. The logo only shows the near wing; in flight a shaded copy
/// behind the body plays the far one, offset towards the head the way it
/// appears on a bird seen from the side, and it folds back exactly behind the
/// near wing as the bird glides in. Once it lands, the original [restAsset]
/// replaces the layers, so the final logo is exactly the launcher artwork with
/// no seam where they were cut.
///
/// On landing a band of light sweeps once across the logo, lighting its
/// outline and faintly its surface, over a warm halo that settles to a soft
/// steady glow.
///
/// Every blur is baked into the assets, so nothing is blurred per frame, and
/// at most two layers are composited at any moment.
///
/// With the platform's reduce-motion setting on, the bird simply fades in.
class FlyingLogo extends StatefulWidget {
  const FlyingLogo({
    required this.restAsset,
    required this.size,
    required this.delay,
    required this.duration,
    this.onLanded,
    this.onFinished,
    super.key,
  });

  final String restAsset;
  final double size;
  final Duration delay;
  final Duration duration;

  /// Called as the bird touches down (with reduced motion: once the logo has
  /// faded in).
  final VoidCallback? onLanded;

  /// Called once the whole sequence, landing light included, has played out.
  final VoidCallback? onFinished;

  static const _bodyAsset = 'assets/icon/dove_body.png';
  static const _wingAsset = 'assets/icon/dove_wing.png';
  static const _farWingAsset = 'assets/icon/dove_wing_far.png';
  static const _rimAsset = 'assets/icon/dove_rim.png';
  static const _rimGlowAsset = 'assets/icon/dove_rim_glow.png';
  static const _haloAsset = 'assets/icon/dove_halo.png';

  @override
  State<FlyingLogo> createState() => _FlyingLogoState();
}

class _FlyingLogoState extends State<FlyingLogo>
    with TickerProviderStateMixin {
  // Wing beats over the flight. Whole, so the last one ends with the wings
  // back up, as in the logo.
  static const _beats = 6;
  // Share of each beat spent on the downstroke. Birds pull down fast and
  // recover slowly; an even split looks mechanical.
  static const _downstrokeShare = 0.4;
  // The shoulder the wings swing about, as a fraction of the square artwork
  // (traced on the 1024px source).
  static const _shoulder = FractionalOffset(548 / 1024, 545 / 1024);
  // At the bottom of a beat the wing is flipped just below the shoulder line
  // to this vertical scale and swung back by this angle.
  static const _wingDownScale = -0.15;
  static const _wingDownAngle = -18 * math.pi / 180;
  // The body rises against each downstroke, by this fraction of its size.
  static const _bodyLift = 0.03;

  // The far wing, relative to the near one at full flap: shifted towards the
  // head and up (fractions of the artwork), opened a little further forward,
  // a touch smaller for distance, and trailing the near wing's beat slightly.
  static const _farWingShift = Offset(0.05, -0.03);
  static const _farWingSpread = 9 * math.pi / 180;
  static const _farWingScale = 0.94;
  static const _farWingLag = 0.05;

  // The bird keeps its final size throughout and comes in from beyond the
  // left edge of the screen. Horizontally it starts this far past the edge
  // (in multiples of its size, beyond half its box); vertically it starts a
  // little low and the path bows gently upward before settling, so it reads
  // as a flight rather than a slide.
  static const _offscreenMargin = 0.1;
  static const _startDy = 0.15;
  static const _arcLift = -0.12;
  // Already moving when it comes into view, slowing gently onto its spot.
  static const _flightCurve = Cubic(0.25, 0.1, 0.35, 1);

  // The light sweep after touchdown.
  static const _sweepDuration = Duration(milliseconds: 1800);
  // Near-even pace, so the band glides across instead of darting through
  // the middle.
  static const _sweepCurve = Curves.easeInOutSine;
  // How far the band's centre travels each way from the middle of the logo
  // (fraction of the box along the diagonal): just enough to start and end
  // clear of the artwork, so the whole sweep is spent on it.
  static const _sweepReach = 0.45;
  // The halo peaks with the sweep, then stays on at the resting level.
  static const _haloPeak = 0.45;
  static const _haloRest = 0.18;
  // Strength of the sheen on the logo's surface (the outline gets full).
  static const _surfaceSheen = 0.18;
  static const _lightColor = Color(0xFFFFF4E2);

  late final AnimationController _flight = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      widget.onLanded?.call();
      if (_reducedMotion) {
        widget.onFinished?.call();
      } else {
        _sweep.forward();
      }
    });
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: _sweepDuration,
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onFinished?.call();
    });
  Timer? _startTimer;
  bool _started = false;
  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_started) return;
    _started = true;
    // Every layer is decoded before the bird sets off. Started on a timer
    // alone, a slow first launch drew the opening frames with layers still
    // missing, so the bird looked cut off until they arrived.
    Future.wait([
      for (final asset in [
        FlyingLogo._bodyAsset,
        FlyingLogo._wingAsset,
        FlyingLogo._farWingAsset,
        FlyingLogo._rimAsset,
        FlyingLogo._rimGlowAsset,
        FlyingLogo._haloAsset,
        widget.restAsset,
      ])
        precacheImage(AssetImage(asset), context),
    ]).whenComplete(() {
      if (!mounted) return;
      _startTimer = Timer(widget.delay, () {
        if (mounted) _flight.forward();
      });
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _flight.dispose();
    _sweep.dispose();
    super.dispose();
  }

  /// One square artwork layer. [opacity] and [color] are applied while
  /// painting the image itself, which costs no extra compositing layer.
  Widget _image(String asset, {double opacity = 1, Color? color}) {
    return Image.asset(
      asset,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      opacity: opacity == 1 ? null : AlwaysStoppedAnimation(opacity),
      color: color,
      colorBlendMode: color == null ? null : BlendMode.srcIn,
      // The wordmark beneath already names the app for screen readers.
      excludeFromSemantics: true,
      gaplessPlayback: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return AnimatedBuilder(
        animation: _flight,
        builder: (context, child) =>
            Opacity(opacity: _flight.value, child: child),
        child: _image(widget.restAsset),
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flight, _sweep]),
        builder: (context, _) => _flight.isCompleted
            ? _landed(_sweep.value)
            : _inFlight(_flight.value, screenWidth),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Flight

  /// 1 while flapping, falling to 0 over the last stretch as the bird glides
  /// onto its spot. Everything that departs from the static logo scales by it.
  double _flap(double t) =>
      1 - Curves.easeInCubic.transform((t / 0.92).clamp(0.0, 1.0));

  /// How far down a wing is at flight progress [t], shifted back by [lag]
  /// beats: 0 raised (as in the logo), 1 at the bottom of the stroke — a
  /// quicker pull down, then a slower lift, each eased at both ends.
  double _stroke(double t, {double lag = 0}) {
    final phase = (_beats * t - lag) % 1;
    return phase < _downstrokeShare
        ? Curves.easeInOut.transform(phase / _downstrokeShare)
        : 1 -
            Curves.easeInOut.transform(
              (phase - _downstrokeShare) / (1 - _downstrokeShare),
            );
  }

  /// A wing swung [down] (0..1) about the shoulder.
  Widget _swing(Widget wing, double down, {double extraAngle = 0}) {
    return Transform(
      alignment: _shoulder,
      transform: Matrix4.rotationZ(_wingDownAngle * down + extraAngle)
        ..scaleByDouble(1, 1 + (_wingDownScale - 1) * down, 1, 1),
      child: wing,
    );
  }

  /// The bird at flight progress [t]. The logo sits centred on the screen,
  /// so the left edge is half a [screenWidth] away from its landing spot.
  Widget _inFlight(double t, double screenWidth) {
    final p = _flightCurve.transform(t);
    final s = widget.size;

    // Quadratic Bézier from the start, via the control point, to (0, 0).
    final start = Offset(
      -(screenWidth / 2 + s * (0.5 + _offscreenMargin)),
      _startDy * s,
    );
    final control = Offset(start.dx / 2, _arcLift * s);
    final q = 1 - p;
    final position = start * (q * q) + control * (2 * q * p);

    // Bank along the direction of travel, levelling out on landing. The
    // artwork already faces up-right, so only part of the angle is applied.
    final tangent = (control - start) * (2 * q) - control * (2 * p);
    final bank = math.atan2(tangent.dy, tangent.dx) * 0.35 * (1 - p);

    final flap = _flap(t);
    final down = _stroke(t) * flap;
    final farDown = _stroke(t, lag: _farWingLag) * flap;

    return Transform.translate(
      offset: position + Offset(0, -_bodyLift * s * down),
      child: Transform.rotate(
        angle: bank,
        child: Stack(
          children: [
            Transform.translate(
              offset: _farWingShift * s * flap,
              child: Transform.scale(
                scale: 1 + (_farWingScale - 1) * flap,
                child: _swing(
                  _image(FlyingLogo._farWingAsset, opacity: flap),
                  farDown,
                  extraAngle: _farWingSpread * flap,
                ),
              ),
            ),
            _image(FlyingLogo._bodyAsset),
            _swing(_image(FlyingLogo._wingAsset), down),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Landing light

  Widget _landed(double t) {
    final rest = _image(widget.restAsset);
    // Rises from nothing to its peak as the band crosses, then eases down
    // to the resting level and stays there.
    final haloOpacity = t < 0.5
        ? _haloPeak * Curves.easeOut.transform(t / 0.5)
        : _haloRest +
            (_haloPeak - _haloRest) *
                (1 - Curves.easeInOut.transform((t - 0.5) / 0.5));
    final halo = _image(
      FlyingLogo._haloAsset,
      color: AppColors.apricot,
      opacity: haloOpacity,
    );
    if (t == 0 || t == 1) return Stack(children: [halo, rest]);

    // The band travels diagonally, top-left to bottom-right.
    final travel = _sweepReach * (2 * _sweepCurve.transform(t) - 1);
    Shader band(Rect bounds, double peak) => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _lightColor.withValues(alpha: 0),
            _lightColor.withValues(alpha: peak),
            _lightColor.withValues(alpha: 0),
          ],
          stops: const [0.35, 0.5, 0.65],
          transform: _Slide(travel),
        ).createShader(bounds);

    return Stack(
      children: [
        halo,
        // Surface sheen: the band painted over the logo, clipped to it.
        ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => band(bounds, _surfaceSheen),
          child: rest,
        ),
        // Outline light: bloom and crisp edge, revealed only under the band.
        ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) => band(bounds, 1),
          child: Stack(
            children: [
              _image(FlyingLogo._rimGlowAsset, color: AppColors.apricot),
              _image(FlyingLogo._rimAsset, color: _lightColor),
            ],
          ),
        ),
      ],
    );
  }
}

/// Moves a gradient along its own diagonal by [amount] of the box (−1..1).
class _Slide extends GradientTransform {
  const _Slide(this.amount);

  final double amount;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(
        bounds.width * amount,
        bounds.height * amount,
        0,
      );
}
