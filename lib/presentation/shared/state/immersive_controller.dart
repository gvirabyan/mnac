import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the home screen is in immersive mode: all foreground UI (and the
/// bottom navigation bar) is hidden so only the background image shows.
///
/// Toggled by press-and-hold on the home screen — held = true, released = false.
class ImmersiveController extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) {
    if (state != value) state = value;
  }
}

final immersiveProvider =
    NotifierProvider<ImmersiveController, bool>(ImmersiveController.new);
