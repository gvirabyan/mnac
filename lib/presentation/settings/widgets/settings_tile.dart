import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';

/// A tappable settings row with a leading icon, title, optional subtitle/value,
/// and optional trailing widget.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  }) : assert((icon == null) != (leading == null));

  /// What leads the row: [icon], or [leading] for a glyph that is not a
  /// Material icon. Exactly one of the two.
  final IconData? icon;
  final Widget Function(Color color, double size)? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = destructive ? theme.colorScheme.error : theme.colorScheme.onSurface;
    final iconColor = destructive ? theme.colorScheme.error : theme.colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
        child: Row(
          children: [
            leading?.call(iconColor, AppSizes.iconMd) ??
                Icon(icon, color: iconColor, size: AppSizes.iconMd),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(color: color)),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSizes.xxs),
                    Text(subtitle!, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
