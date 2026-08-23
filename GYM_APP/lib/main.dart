import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'core/localization/app_translations.dart';
import 'core/localization/locale_controller.dart';
import 'core/navigation/navigator_key.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/responsive.dart';
import 'features/splash/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final initialLocale = await LocaleController.resolveInitialLocale();
  Get.put(LocaleController()).locale.value = initialLocale;

  runApp(MyApp(initialLocale: initialLocale));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.initialLocale});

  final Locale initialLocale;

  @override
  Widget build(BuildContext context) {
    // Built fresh from the current MediaQuery (available here even above
    // GetMaterialApp — runApp wraps everything in a View, which provides
    // MediaQuery to its whole subtree since Flutter 3.10) so every screen
    // reading its text style from Theme.of(context) scales to the
    // device's screen size automatically. See core/theme/responsive.dart.
    final textScale = Responsive.textScaleOf(context);
    return GetMaterialApp(
      title: 'Gym App',
      debugShowCheckedModeBanner: false,
      // Lets ApiClient redirect to the login screen on a 401 without
      // needing a BuildContext of its own — see core/services/api_client.dart.
      navigatorKey: navigatorKey,
      theme: AppTheme.buildLightTheme(textScale),
      darkTheme: AppTheme.buildDarkTheme(textScale),
      themeMode: ThemeMode.dark,
      translations: AppTranslations(),
      locale: initialLocale,
      fallbackLocale: LocaleController.english,
      supportedLocales: const [
        LocaleController.english,
        LocaleController.arabic,
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
