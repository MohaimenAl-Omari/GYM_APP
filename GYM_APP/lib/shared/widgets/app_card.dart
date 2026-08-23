import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'animated_tap.dart';

/// Standard elevated surface used across the app for list items, stat
/// tiles, and section containers. Centralizes the card radius/border/shadow
/// so every screen looks consistent, and folds in [AnimatedTap] press
/// feedback automatically when [onTap] is provided.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.borderColor,
    this.borderRadius = 20,
    this.withShadow = true,
    this.margin,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double borderRadius;
  final bool withShadow;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.darkCard,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? AppColors.darkBorderSubtle),
        boxShadow: withShadow ? AppColors.softShadow : null,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return AnimatedTap(onTap: onTap, borderRadius: radius, child: content);
  }
}
