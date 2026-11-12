import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';

/// A slow, shared "breathing" beat for the accent glows on Home, so every
/// glow rises and fades together rather than each on its own clock.
///
/// Descendants read the beat with [GlowPulse.of] (0 = faintest, 1 =
/// brightest). When [enabled] is false, or the system asks for reduced
/// motion, the beat holds still at its brightest.
class GlowPulse extends StatefulWidget {
  const GlowPulse({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  /// One full rise and fall takes twice this.
  static const Duration halfPeriod = Duration(milliseconds: 2600);

  static Animation<double> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GlowScope>()?.beat ??
      kAlwaysCompleteAnimation;

  @override
  State<GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<GlowPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: GlowPulse.halfPeriod);
  late final Animation<double> _beat =
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

  /// Null until the first sync, so a beat that starts disabled is still set
  /// to its brightest.
  bool? _running;

  void _sync(bool shouldRun) {
    if (shouldRun == _running) return;
    _running = shouldRun;
    if (shouldRun) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 1;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync(widget.enabled && !MediaQuery.disableAnimationsOf(context));
  }

  @override
  void didUpdateWidget(GlowPulse old) {
    super.didUpdateWidget(old);
    _sync(widget.enabled && !MediaQuery.disableAnimationsOf(context));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _GlowScope(beat: _beat, child: widget.child);
  }
}

class _GlowScope extends InheritedWidget {
  const _GlowScope({required this.beat, required super.child});

  final Animation<double> beat;

  @override
  bool updateShouldNotify(_GlowScope old) => old.beat != beat;
}

/// A soft accent halo behind [child] that breathes with [GlowPulse]. The
/// halo is a blurred shadow with no fill, so it reads as light around the
/// element, not as a box.
class GlowHalo extends StatelessWidget {
  const GlowHalo({
    super.key,
    required this.child,
    this.low = 0.06,
    this.high = 0.20,
  });

  final Widget child;

  /// Halo opacity at the faintest and brightest point of the beat.
  final double low;
  final double high;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final beat = GlowPulse.of(context);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: beat,
        builder: (context, child) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(
                  alpha: low + (high - low) * beat.value,
                ),
                blurRadius: 24,
                spreadRadius: -6,
              ),
            ],
          ),
          child: child,
        ),
        child: child,
      ),
    );
  }
}
