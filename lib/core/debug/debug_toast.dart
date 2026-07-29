import 'package:flutter/material.dart';

/// TEMP debug helper: surfaces log messages as on-screen SnackBars so they're
/// visible in a TestFlight build, where there's no attached console.
/// Wire [debugMessengerKey] into MaterialApp.scaffoldMessengerKey; remove
/// both once ad diagnostics are done.
final GlobalKey<ScaffoldMessengerState> debugMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void showDebugToast(String message) {
  debugMessengerKey.currentState?.showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
  );
}
