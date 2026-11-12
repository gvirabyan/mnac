import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';

/// A calm card: a faint fill and a hairline border, no shadow or blur, so
/// the content carries it. Optionally tappable, with the ripple clipped to
/// the rounded shape.
class QuietCard extends StatelessWidget {
  const QuietCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSizes.md),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: ink.withValues(alpha: 0.03),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        side: BorderSide(color: ink.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
