import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../presentation/language/language_picker_dialog.dart';
import '../../presentation/shell/main_shell.dart';
import '../../presentation/splash/splash_screen.dart';
import '../startup_sequence.dart';

/// App entry point. Plays the animated splash first, then crossfades into
/// the main shell; adding a soldier happens from the home screen's empty
/// state (no separate onboarding flow).
///
/// The splash finishing is also what releases the startup consent prompts:
/// raised any earlier they would cover the splash. See [runStartupSequence].
/// On a fresh install the language picker comes first, so those prompts and
/// the ad SDK (which depends on the language) follow the user's choice.
class RootGate extends ConsumerStatefulWidget {
  const RootGate({super.key});

  @override
  ConsumerState<RootGate> createState() => _RootGateState();
}

class _RootGateState extends ConsumerState<RootGate> {
  bool _showSplash = true;

  Future<void> _onSplashFinished() async {
    setState(() => _showSplash = false);
    if (ref.read(languageChoicePendingProvider)) {
      await showLanguagePicker(context);
      if (!mounted) return;
    }
    // Not awaited: the shell is already on screen and nothing it shows waits
    // on the outcome.
    runStartupSequence(ref);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _showSplash
          ? SplashScreen(
              key: const ValueKey('splash'),
              onFinished: _onSplashFinished,
            )
          : const MainShell(key: ValueKey('main')),
    );
  }
}

/// Shared-axis style fade+slide route used for pushed screens.
Route<T> appPageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
