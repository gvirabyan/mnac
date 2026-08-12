import 'package:flutter/foundation.dart';

/// Master switch for the on-screen ad diagnostics.
///
/// Ad events normally go to the device log, which is only readable through
/// Console.app on a tethered Mac — not an option when testing a TestFlight
/// build from the phone alone. With this on, every event is also pushed to
/// [adDebugFeed] and shown as a transient toast, so it can be seen whether
/// mediation is calling Unity and what it answers without any tooling.
///
/// Set to `false` before shipping to the App Store: these toasts are developer
/// diagnostics and must not reach users.
const bool kAdDebugToasts = true;

/// A single ad-pipeline event. A fresh instance per event on purpose — the
/// feed notifies on identity change, so two identical messages in a row still
/// both surface.
class AdDebugEvent {
  AdDebugEvent(this.message) : at = DateTime.now();

  final String message;
  final DateTime at;

  String get clock {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(at.hour)}:${two(at.minute)}:${two(at.second)}';
  }
}

/// The latest ad event, watched by the on-screen overlay.
final ValueNotifier<AdDebugEvent?> adDebugFeed = ValueNotifier(null);

/// Events already recorded, so the overlay can replay what it missed.
///
/// The most valuable events — the mediation adapter statuses — are emitted
/// from `main()` before `runApp`, when no widget exists to hear them. A
/// listener alone would silently drop exactly the lines worth reading.
final List<AdDebugEvent> adDebugHistory = <AdDebugEvent>[];

/// Records an ad event to the device log and, when [kAdDebugToasts] is on, to
/// the on-screen feed.
void logAdEvent(String message) {
  debugPrint('[ads] $message');
  if (!kAdDebugToasts) return;
  final event = AdDebugEvent(message);
  adDebugHistory.add(event);
  if (adDebugHistory.length > 30) adDebugHistory.removeAt(0);
  adDebugFeed.value = event;
}
