import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_gradients.dart';

/// A [Scaffold] with a premium gradient background, plus an optional
/// user-selected background image rendered subtly beneath the content.
class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundImagePath,
    this.extendBodyBehindAppBar = false,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final String? backgroundImagePath;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient =
        isDark ? AppGradients.darkBackground : AppGradients.lightBackground;
    final hasImage =
        backgroundImagePath != null && File(backgroundImagePath!).existsSync();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: gradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Opacity(
                opacity: isDark ? 0.18 : 0.12,
                child: Image.file(
                  File(backgroundImagePath!),
                  fit: BoxFit.cover,
                ),
              ),
            body,
          ],
        ),
      ),
    );
  }
}
