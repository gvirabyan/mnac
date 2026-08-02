import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';

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

/// Apricot bloom behind the wordmark — reads as the logo lighting the screen.
/// Centred slightly above the middle so it sits on the title, not the tagline.
final _glowGradient = RadialGradient(
  center: const Alignment(0, -0.12),
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

/// Animated startup splash: the "Մնաց" wordmark gradually brightens out of
/// black, then the tagline fades in below it. Calls [onFinished] once the
/// sequence has fully played so the caller can swap in the real app.
///
/// Both lines are vector artwork rather than live text: the glyphs are baked
/// to outlines so the gold gradient on the wordmark and the divider above the
/// tagline render identically everywhere, with no webfont fetch on first run.
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
  // Title appears first, on its own. Then a full beat after it has finished,
  // the tagline rises in. Milliseconds (not Duration) so the delay below can
  // be summed as a const expression.
  static const _titleDelayMs = 150;
  static const _titleDurationMs = 900;
  static const _pauseAfterTitleMs = 1000;
  static const _taglineDelayMs =
      _titleDelayMs + _titleDurationMs + _pauseAfterTitleMs;
  static const _taglineDurationMs = 800;

  static const _titleDelay = Duration(milliseconds: _titleDelayMs);
  static const _titleDuration = Duration(milliseconds: _titleDurationMs);
  static const _taglineDelay = Duration(milliseconds: _taglineDelayMs);
  static const _taglineDuration = Duration(milliseconds: _taglineDurationMs);

  // A last unhurried beat with both on screen before handing off.
  static const _holdAfter = Duration(milliseconds: 1100);

  // The glow warms up slower than the wordmark it sits behind, so the screen
  // looks like it is being lit rather than switched on.
  static const _glowDuration = Duration(milliseconds: 1800);

  // The native launch screen is a flat charcoalDeep fill, so the first Flutter
  // frame starts from that exact colour and blooms the gradient in on top —
  // the handoff between the two screens is then invisible.
  static const _backdropDuration = Duration(milliseconds: 700);

  // Artwork widths, as a fraction of the screen capped for tablets. Heights
  // follow from each SVG's own aspect ratio.
  static const _wordmarkWidthFactor = 0.52;
  static const _wordmarkMaxWidth = 230.0;
  static const _taglineWidthFactor = 0.72;
  static const _taglineMaxWidth = 320.0;

  Timer? _finishTimer;

  @override
  void initState() {
    super.initState();
    _finishTimer = Timer(
      _taglineDelay + _taglineDuration + _holdAfter,
      widget.onFinished,
    );
  }

  @override
  void dispose() {
    _finishTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final wordmarkWidth = (screenWidth * _wordmarkWidthFactor).clamp(
      0.0,
      _wordmarkMaxWidth,
    );
    final taglineWidth = (screenWidth * _taglineWidthFactor).clamp(
      0.0,
      _taglineMaxWidth,
    );

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
          ).animate().fadeIn(duration: _glowDuration, curve: Curves.easeInOut),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                      'assets/svg/splash_wordmark.svg',
                      width: wordmarkWidth,
                      semanticsLabel: AppStrings.appName,
                    )
                    .animate()
                    .fadeIn(
                      delay: _titleDelay,
                      duration: _titleDuration,
                      curve: Curves.easeIn,
                    )
                    .scale(
                      begin: const Offset(0.96, 0.96),
                      end: const Offset(1, 1),
                      curve: Curves.easeOut,
                    ),
                const SizedBox(height: 4),
                SvgPicture.asset(
                      'assets/svg/splash_tagline.svg',
                      width: taglineWidth,
                      semanticsLabel: AppStrings.splashTagline,
                    )
                    .animate()
                    .fadeIn(
                      delay: _taglineDelay,
                      duration: _taglineDuration,
                      curve: Curves.easeOut,
                    )
                    .moveY(
                      begin: 8,
                      end: 0,
                      delay: _taglineDelay,
                      duration: _taglineDuration,
                      curve: Curves.easeOut,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
