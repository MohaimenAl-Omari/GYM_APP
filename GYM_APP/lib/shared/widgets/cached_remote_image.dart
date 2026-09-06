import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'skeleton_loader.dart';

/// Renders a remote exercise/muscle-group image or looping GIF with disk
/// caching, a pulsing skeleton while it loads, and a graceful icon
/// fallback when the URL is missing or fails to load. Centralizes the "how
/// do we show a demo image" decision so every screen (exercise list,
/// detail, active workout, history) renders it the same way instead of
/// each hand-rolling its own `Image.network` + `errorBuilder`.
///
/// Animated GIFs keep animating here exactly like they did with plain
/// `Image.network` — `CachedNetworkImage` decodes through Flutter's normal
/// image pipeline once a file is cached, which natively plays every frame
/// of a multi-frame GIF.
class CachedRemoteImage extends StatelessWidget {
  const CachedRemoteImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.iconSize = 32,
  });

  /// Already-resolved URL (see `resolveMediaUrl`) — pass null to always
  /// show the placeholder icon (e.g. the exercise has no media at all).
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final resolved = url;
    if (resolved == null || resolved.isEmpty) {
      return _placeholder();
    }
    return CachedNetworkImage(
      imageUrl: resolved,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, _) => SkeletonBox(
        width: width,
        height: height ?? 100,
        borderRadius: 0,
      ),
      errorWidget: (context, _, __) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.darkSurface,
      alignment: Alignment.center,
      child: Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: iconSize),
    );
  }
}
