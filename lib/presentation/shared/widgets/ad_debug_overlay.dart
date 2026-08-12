import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/ad_debug.dart';

/// Draws ad-pipeline events as transient toasts over the whole app.
///
/// Wrapped around the navigator (via `MaterialApp.builder`) rather than placed
/// on a screen, because the events that matter most arrive during the launch
/// sequence and while a full-screen ad is up — moments when no particular page
/// is reliably mounted.
///
/// Entirely inert when [kAdDebugToasts] is off: it returns [child] untouched,
/// so turning the flag off is enough to remove it from a public build.
class AdDebugOverlay extends StatefulWidget {
  const AdDebugOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<AdDebugOverlay> createState() => _AdDebugOverlayState();
}

class _AdDebugOverlayState extends State<AdDebugOverlay> {
  /// Long enough to still be on screen when you look down at the phone after
  /// the 15s launch delay, short enough not to sit there forever.
  static const _linger = Duration(seconds: 20);
  static const _maxVisible = 6;

  final List<AdDebugEvent> _visible = [];
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    if (!kAdDebugToasts) return;
    // Replay whatever was logged before this overlay existed — the adapter
    // statuses are emitted from main(), well before the first frame.
    final backlog = adDebugHistory.length > _maxVisible
        ? adDebugHistory.sublist(adDebugHistory.length - _maxVisible)
        : adDebugHistory;
    for (final event in backlog) {
      // No setState during initState — the first build renders these anyway.
      _show(event, notify: false);
    }
    adDebugFeed.addListener(_onEvent);
  }

  @override
  void dispose() {
    adDebugFeed.removeListener(_onEvent);
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  void _onEvent() {
    final event = adDebugFeed.value;
    if (event == null || !mounted) return;
    _show(event, notify: true);
  }

  void _show(AdDebugEvent event, {required bool notify}) {
    _visible.add(event);
    if (_visible.length > _maxVisible) _visible.removeAt(0);
    late final Timer timer;
    timer = Timer(_linger, () {
      _timers.remove(timer);
      if (!mounted) return;
      setState(() => _visible.remove(event));
    });
    _timers.add(timer);
    if (notify) setState(() {});
  }

  /// Green for a fill, red for a failure, neutral otherwise — so the outcome
  /// is readable at a glance without parsing the text.
  Color _tint(String message) {
    if (message.startsWith('LOADED')) return const Color(0xFF1B5E20);
    if (message.contains('FAILED') || message.startsWith('nothing')) {
      return const Color(0xFF7F1D1D);
    }
    return const Color(0xFF1F2937);
  }

  @override
  Widget build(BuildContext context) {
    if (!kAdDebugToasts) return widget.child;
    return Stack(
      children: [
        widget.child,
        // IgnorePointer so the toasts never intercept a tap meant for the app.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final event in _visible)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _tint(event.message).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${event.clock}  ${event.message}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            height: 1.3,
                            fontFamily: 'monospace',
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
