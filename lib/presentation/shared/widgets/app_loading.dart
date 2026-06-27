import 'package:flutter/material.dart';

/// A simple centered loading indicator using the accent color.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
        strokeWidth: 3,
      ),
    );
  }
}
