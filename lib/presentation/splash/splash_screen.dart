import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/flying_logo.dart';

/// Backdrop base: warm charcoal at the top deepening to near-black at the
/// bottom, so the screen has a direction of light rather than a flat fill.
final _backdropGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    const Color(0xFF1D1913),
    AppColors.charcoalDeep,
    const Color(0xFF0B0906),
  ],
  stops: const [0, 0.52, 1],
);

/// Apricot bloom centred on the logo — reads as the dove lighting the screen
/// as it lands.
final _glowGradient = RadialGradient(
  radius: 0.85,
  colors: [
    AppColors.apricot.withValues(alpha: 0.17),
    AppColors.apricot.withValues(alpha: 0.06),
    AppColors.apricot.withValues(alpha: 0),
  ],
  stops: const [0, 0.45, 1],
);

/// Corner falloff that keeps the eye on the centre of the screen.
const _vignetteGradient = RadialGradient(
  radius: 1,
  colors: [Color(0x00000000), Color(0x59000000)],
  stops: [0.55, 1],
);

/// The logo. This is deliberately the same file the launcher icon is
/// generated from (see the `flutter_launcher_icons` block in pubspec), not a
/// separate copy: replacing the logo there and re-running the generator
/// updates the splash too, with nothing to keep in sync by hand.
const _logoAsset = 'assets/icon/icon_foreground.png';

/// Animated startup splash: the logo dove flies in and lands in the centre of
/// the screen (see [FlyingLogo]), the glow and the "Մնաց" wordmark below it
/// come up as it touches down, and a band of light crosses the logo. Calls
/// [onFinished] once that has fully played, so the caller can swap in the
/// real app.
///
/// The sequence is driven by the animation's own events, not by a clock: on
/// a slow cold start the first frames arrive late, and a timer started at
/// launch used to close the splash before the animation had finished.
///
/// The wordmark is vector artwork rather than live text: its glyphs are baked
/// to outlines so the gold gradient renders identically everywhere, with no
/// webfont fetch on first run.
///
/// The OS launch screen (see the `flutter_native_splash` block in pubspec) is
/// a bare charcoalDeep fill with no artwork on either platform, and this
/// screen opens on that same colour — so the app appears to boot straight
/// into the splash rather than flashing a launcher icon first.
class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.onFinished, super.key});

  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _logoDelay = Duration(milliseconds: 150);
  // Slow and calm on purpose: the dove crosses half the screen at full size.
  static const _logoDuration = Duration(milliseconds: 4000);

  // The wordmark brightens in as the dove touches down.
  static const _titleDuration = Duration(milliseconds: 900);

  // The glow warms up with the landing and slower than the wordmark, so the
  // screen looks like it is being lit rather than switched on.
  static const _glowDuration = Duration(milliseconds: 1500);

  // A last unhurried beat on the finished screen before handing off.
  static const _holdAfter = Duration(milliseconds: 600);

  // Hands off regardless if the sequence never reports back (say, an asset
  // that fails to decode), so the app can't get stuck behind the splash.
  // Well above the ~6.5 s the sequence takes, so a slow device never trips it.
  static const _failsafe = Duration(seconds: 15);

  // The native launch screen is a flat charcoalDeep fill, so the first Flutter
  // frame starts from that exact colour and blooms the gradient in on top —
  // the handoff between the two screens is then invisible.
  static const _backdropDuration = Duration(milliseconds: 700);

  // Artwork widths, as a fraction of the screen capped for tablets. The logo
  // is square and its source carries its own padding, so the drawn bird
  // fills less than the box.
  static const _logoWidthFactor = 0.56;
  static const _logoMaxWidth = 240.0;
  static const _wordmarkWidthFactor = 0.34;
  static const _wordmarkMaxWidth = 150.0;

  // The wordmark sits low on the screen, well under the centred logo
  // (Alignment y: 0 is the middle, 1 the bottom edge).
  static const _wordmarkAlignment = Alignment(0, 0.75);

  bool _landed = false;
  bool _finished = false;
  Timer? _holdTimer;
  Timer? _failsafeTimer;

  @override
  void initState() {
    super.initState();
    _failsafeTimer = Timer(_failsafe, _finish);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _failsafeTimer?.cancel();
    super.dispose();
  }

  void _onLanded() {
    if (mounted) setState(() => _landed = true);
  }

  void _onLogoFinished() {
    _holdTimer = Timer(_holdAfter, _finish);
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    _holdTimer?.cancel();
    _failsafeTimer?.cancel();
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final logoWidth = (screenWidth * _logoWidthFactor).clamp(
      0.0,
      _logoMaxWidth,
    );
    final wordmarkWidth = (screenWidth * _wordmarkWidthFactor).clamp(
      0.0,
      _wordmarkMaxWidth,
    );
    final landed = _landed ? 1.0 : 0.0;

    return ColoredBox(
      color: AppColors.charcoalDeep,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: BoxDecoration(gradient: _backdropGradient))
              .animate()
              .fadeIn(duration: _backdropDuration, curve: Curves.easeOut),
          const DecoratedBox(
            decoration: BoxDecoration(gradient: _vignetteGradient),
          ).animate().fadeIn(
            duration: _backdropDuration,
            curve: Curves.easeOut,
          ),
          DecoratedBox(
            decoration: BoxDecoration(gradient: _glowGradient),
          ).animate(target: landed).fadeIn(
            duration: _glowDuration,
            curve: Curves.easeInOut,
          ),
          Center(
            // Its own layer, so the flight and the light sweep repaint only
            // the logo, not the gradients behind it.
            child: RepaintBoundary(
              child: FlyingLogo(
                restAsset: _logoAsset,
                size: logoWidth,
                delay: _logoDelay,
                duration: _logoDuration,
                onLanded: _onLanded,
                onFinished: _onLogoFinished,
              ),
            ),
          ),
          Align(
            alignment: _wordmarkAlignment,
            child: SvgPicture.asset(
                  'assets/svg/splash_wordmark.svg',
                  width: wordmarkWidth,
                  semanticsLabel: AppStrings.appName,
                )
                .animate(target: landed)
                .fadeIn(duration: _titleDuration, curve: Curves.easeIn)
                .scale(
                  begin: const Offset(0.96, 0.96),
                  end: const Offset(1, 1),
                  duration: _titleDuration,
                  curve: Curves.easeOut,
                ),
          ),
        ],
      ),
    );
  }
}
