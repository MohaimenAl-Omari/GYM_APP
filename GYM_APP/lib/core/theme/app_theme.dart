import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Custom page transition: a gentle fade + upward slide, used for every
/// pushed route across the app (Navigator.push and MaterialPageRoute both
/// pick this up automatically via [ThemeData.pageTransitionsTheme]).
class _AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const _AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

final PageTransitionsTheme _pageTransitionsTheme = const PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.android: _AppPageTransitionsBuilder(),
    TargetPlatform.iOS: _AppPageTransitionsBuilder(),
    TargetPlatform.macOS: _AppPageTransitionsBuilder(),
    TargetPlatform.linux: _AppPageTransitionsBuilder(),
    TargetPlatform.windows: _AppPageTransitionsBuilder(),
  },
);

/// [scale] comes from [Responsive.textScaleOf] (see main.dart, where the
/// theme is built per-frame from the current MediaQuery) — this is what
/// makes every screen that reads its text style from `Theme.of(context)`
/// (headings, body text, buttons, dialogs, chips, snackbars, inputs)
/// responsive to the device's screen size for free, without each screen
/// needing to scale its own TextStyle by hand.
TextTheme _buildTextTheme(Color base, Color muted, double scale) {
  return TextTheme(
    headlineLarge: TextStyle(fontSize: 28 * scale, fontWeight: FontWeight.w800, color: base, height: 1.2),
    headlineMedium: TextStyle(fontSize: 24 * scale, fontWeight: FontWeight.w700, color: base, height: 1.2),
    headlineSmall: TextStyle(fontSize: 20 * scale, fontWeight: FontWeight.w700, color: base, height: 1.25),
    titleLarge: TextStyle(fontSize: 18 * scale, fontWeight: FontWeight.w700, color: base, height: 1.3),
    titleMedium: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w600, color: base, height: 1.3),
    titleSmall: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.w600, color: base, height: 1.3),
    bodyLarge: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w400, color: base, height: 1.4),
    bodyMedium: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.w400, color: base, height: 1.4),
    bodySmall: TextStyle(fontSize: 13 * scale, fontWeight: FontWeight.w400, color: muted, height: 1.4),
    labelLarge: TextStyle(fontSize: 15 * scale, fontWeight: FontWeight.w600, color: base, height: 1.2),
    labelMedium: TextStyle(fontSize: 13 * scale, fontWeight: FontWeight.w500, color: base, height: 1.2),
    labelSmall: TextStyle(fontSize: 12 * scale, fontWeight: FontWeight.w500, color: muted, height: 1.2),
  );
}

class AppTheme {
  /// [textScale] should come from [Responsive.textScaleOf] — built fresh
  /// per-frame in main.dart from the current MediaQuery so the whole theme
  /// (and everything built from it) responds to the device's screen size.
  static ThemeData buildDarkTheme(double textScale) => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    primaryColor: AppColors.primary,
    splashFactory: InkRipple.splashFactory,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.textWhite,
      secondary: AppColors.primaryLight,
      onSecondary: AppColors.textWhite,
      surface: AppColors.darkSurface,
      onSurface: AppColors.textWhite,
      error: AppColors.error,
      onError: AppColors.textWhite,
    ),
    textTheme: _buildTextTheme(AppColors.textWhite, AppColors.textGrey, textScale).apply(
      fontFamily: 'SF Pro Display',
    ),
    pageTransitionsTheme: _pageTransitionsTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.textWhite,
      iconTheme: const IconThemeData(color: AppColors.textWhite),
      titleTextStyle: TextStyle(
        color: AppColors.textWhite,
        fontSize: 18 * textScale,
        fontWeight: FontWeight.w700,
        fontFamily: 'SF Pro Display',
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.darkBorderSubtle),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.darkDivider,
      thickness: 1,
      space: 1,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
        disabledForegroundColor: AppColors.textWhite.withValues(alpha: 0.7),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: TextStyle(
          fontSize: 16 * textScale,
          fontWeight: FontWeight.w700,
          fontFamily: 'SF Pro Display',
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textWhite,
        side: const BorderSide(color: AppColors.darkBorder),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: TextStyle(
          fontSize: 15 * textScale,
          fontWeight: FontWeight.w600,
          fontFamily: 'SF Pro Display',
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: TextStyle(
          fontSize: 14 * textScale,
          fontWeight: FontWeight.w600,
          fontFamily: 'SF Pro Display',
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkCard,
      selectedColor: AppColors.primary.withValues(alpha: 0.18),
      disabledColor: AppColors.darkCard,
      labelStyle: TextStyle(
        color: AppColors.textWhite,
        fontSize: 13 * textScale,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: TextStyle(color: AppColors.primary, fontSize: 13 * textScale),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      side: const BorderSide(color: AppColors.darkBorder),
      shape: const StadiumBorder(),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkCardElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: TextStyle(
        color: AppColors.textWhite,
        fontSize: 18 * textScale,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: TextStyle(
        color: AppColors.textLightGrey,
        fontSize: 14 * textScale,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkCardElevated,
      contentTextStyle: TextStyle(color: AppColors.textWhite, fontSize: 14 * textScale),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      hintStyle: TextStyle(color: AppColors.textGrey, fontSize: 14 * textScale),
    ),
    fontFamily: 'SF Pro Display',
  );

  static ThemeData buildLightTheme(double textScale) => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    primaryColor: AppColors.primary,
    splashFactory: InkRipple.splashFactory,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.textWhite,
      secondary: AppColors.primaryDark,
      onSecondary: AppColors.textWhite,
      surface: AppColors.lightSurface,
      onSurface: AppColors.textDark,
      error: AppColors.error,
      onError: AppColors.textWhite,
    ),
    textTheme: _buildTextTheme(AppColors.textDark, AppColors.textMuted, textScale).apply(
      fontFamily: 'SF Pro Display',
    ),
    pageTransitionsTheme: _pageTransitionsTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.textDark,
      iconTheme: const IconThemeData(color: AppColors.textDark),
      titleTextStyle: TextStyle(
        color: AppColors.textDark,
        fontSize: 18 * textScale,
        fontWeight: FontWeight.w700,
        fontFamily: 'SF Pro Display',
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.lightBorderSubtle),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.lightDivider,
      thickness: 1,
      space: 1,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: TextStyle(
          fontSize: 16 * textScale,
          fontWeight: FontWeight.w700,
          fontFamily: 'SF Pro Display',
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle: TextStyle(color: AppColors.textGrey, fontSize: 14 * textScale),
    ),
    fontFamily: 'SF Pro Display',
  );
}
