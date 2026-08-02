import 'package:flutter/material.dart';

import '../../presentation/shell/main_shell.dart';
import '../../presentation/splash/splash_screen.dart';

/// App entry point. Plays the animated splash first, then crossfades into
/// the main shell; adding a soldier happens from the home screen's empty
/// state (no separate onboarding flow).
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _showSplash
          ? SplashScreen(
              key: const ValueKey('splash'),
              onFinished: () => setState(() => _showSplash = false),
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
