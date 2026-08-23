import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A single pulsing placeholder box, used to build skeleton loading states
/// instead of a bare [CircularProgressIndicator] while a [FutureBuilder]
/// resolves.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(begin: 0.35, end: 0.75).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.darkCardElevated.withValues(alpha: _opacity.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// A ready-made skeleton card matching [AppCard]'s footprint, for list-style
/// loading states (history items, exercise cards, etc).
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 84, this.margin});

  final double height;
  final EdgeInsetsGeometry? margin;

  /// Content is always two fixed lines (16 + 10 gap + 12 = 38dp). A flat
  /// 18dp padding on every side worked for the default 84dp card but
  /// silently overflowed ("RenderFlex overflowed by 4.0 pixels") for any
  /// caller passing a shorter height (e.g. the 72dp exercise-list variant,
  /// where 18dp padding only left 36dp for content that needs 38dp).
  /// Scaling the padding down for shorter cards keeps every height that
  /// actually has room for the content overflow-free automatically,
  /// instead of hardcoding a fix for just the one height that broke.
  double get _verticalPadding => ((height - 38) / 2).clamp(4.0, 18.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: _verticalPadding),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SkeletonBox(width: 140, height: 16),
          SizedBox(height: 10),
          SkeletonBox(width: 90, height: 12),
        ],
      ),
    );
  }
}
