import 'package:flutter/material.dart';

/// Fluid scaling for phone screens of different sizes. This app's spacing
/// and type scale were originally hand-tuned against a ~375dp-wide design
/// (the standard iPhone reference width) — on a compact phone (iPhone SE,
/// ~360dp) that reads slightly cramped, and on a large one (Pro Max,
/// ~430dp+) there's noticeably more unused breathing room than intended.
///
/// Scoped to phones only (no tablet/landscape-specific layouts) per
/// product decision — this is fluid scaling within the normal phone width
/// range, not a breakpoint system. No new dependency: this is the
/// project's "no new UI packages without confirming" convention applied
/// to responsiveness too.
class Responsive {
  Responsive._();

  /// The width this app's spacing/type values were originally designed
  /// against (see class doc).
  static const double baseWidth = 375;

  /// Bounds for [scaleOf] — kept gentle so spacing/icon sizing feels
  /// tailored to the device without ever ballooning or shrinking
  /// drastically between the smallest and largest phones in common use.
  static const double minScale = 0.88;
  static const double maxScale = 1.15;

  /// Bounds for text scaling specifically — narrower than [minScale]/
  /// [maxScale] because legibility matters more than proportional spacing:
  /// text shouldn't swing as widely as padding does across device sizes.
  static const double minTextScale = 0.92;
  static const double maxTextScale = 1.10;

  /// General-purpose scale factor for spacing, icon sizes, and radii.
  static double scaleOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return (width / baseWidth).clamp(minScale, maxScale);
  }

  /// Same idea as [scaleOf] but for a raw width value — used by
  /// [AppTheme] to scale the TextTheme, which is built once per
  /// theme (in main.dart, from MediaQuery) rather than per-widget.
  static double textScaleForWidth(double width) {
    return (width / baseWidth).clamp(minTextScale, maxTextScale);
  }

  /// Text-specific scale factor for the current context.
  static double textScaleOf(BuildContext context) {
    return textScaleForWidth(MediaQuery.sizeOf(context).width);
  }
}

extension ResponsiveNum on num {
  /// Scales a spacing/padding/icon-size value written against the app's
  /// 375dp design baseline to the current device's width. Do NOT use this
  /// on a fixed touch-target dimension (e.g. the app's 48x48dp minimum
  /// tap targets) — those must stay at least 48dp on every device
  /// regardless of scaling, per the gym-app-mobile-ui-ux skill.
  double rs(BuildContext context) => this * Responsive.scaleOf(context);

  /// Scales a font size using the narrower text-scale clamp — use this
  /// for `TextStyle(fontSize: ...)` values that live outside the app's
  /// shared [AppTheme] TextTheme (which already scales itself; see
  /// main.dart). Widgets that pull their style from
  /// `Theme.of(context).textTheme.*` don't need this — they're already
  /// covered.
  double rf(BuildContext context) => this * Responsive.textScaleOf(context);
}
