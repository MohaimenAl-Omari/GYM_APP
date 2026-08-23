import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/responsive.dart';

/// Shared empty/error state layout: icon in a soft circular badge, a
/// message, and an optional retry action. Used wherever a screen has
/// nothing to show (empty list, failed fetch).
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 40.rs(context),
        horizontal: 24.rs(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.textGrey).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor ?? AppColors.textGrey, size: 32),
          ),
          SizedBox(height: 16.rs(context)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey, fontSize: 14.rf(context), height: 1.4),
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: 20.rs(context)),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
