import 'package:flutter/material.dart';

/// Central design-token palette for the app.
///
/// Kept intentionally flat (no theme-aware lookups) since dark mode is
/// currently hardcoded on ([ThemeMode.dark] in main.dart) — but the
/// light-theme tokens are kept in sync so re-enabling light mode later
/// doesn't require re-deriving them.
class AppColors {
  // Primary
  static const Color primary = Color(0xFFFF6B35); // Energy Orange
  static const Color primaryDark = Color(0xFFE85A24);
  static const Color primaryLight = Color(0xFFFF8A5C);

  /// Diagonal gradient used for hero CTAs (Start Workout, primary buttons).
  static const List<Color> primaryGradient = [primary, primaryDark];

  // Dark theme surfaces (layered from background -> floating elements)
  static const Color darkBackground = Color(0xFF0D0D0D);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkCard = Color(0xFF232323);
  static const Color darkCardElevated = Color(0xFF2A2A2A);
  static const Color darkBorder = Color(0xFF2E2E2E);
  static const Color darkBorderSubtle = Color(0xFF242424);
  static const Color darkDivider = Color(0xFF242424);

  // Light theme
  static const Color lightBackground = Color(0xFFF4F4F4);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardElevated = Color(0xFFFAFAFA);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightBorderSubtle = Color(0xFFEAEAEA);
  static const Color lightDivider = Color(0xFFE8E8E8);

  // Text
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF111111);
  static const Color textGrey = Color(0xFF8A8A8A);
  static const Color textLightGrey = Color(0xFFB0B0B0);
  static const Color textMuted = Color(0xFF6B6B6B);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF4FA8E8);

  // Chart / data-viz accents (progress bars, trend charts)
  static const Color chartBarActive = primary;
  static const Color chartBarInactive = Color(0xFF3A3A3A);
  static const Color chartGrid = Color(0xFF262626);

  // Shadows / overlays
  static const Color shadow = Color(0x40000000); // black @ 25%
  static const Color shadowSoft = Color(0x26000000); // black @ 15%
  static const Color scrim = Color(0xB3000000); // black @ 70%
  static const Color overlayOnCard = Color(0x14FFFFFF); // white @ 8%

  /// Reusable soft drop shadow for elevated dark-theme cards.
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: shadow,
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  /// Subtler shadow for inline/compact elements (chips, small buttons).
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: shadowSoft,
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  /// Glow used behind primary CTA buttons for a touch of energy.
  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.35),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
}
