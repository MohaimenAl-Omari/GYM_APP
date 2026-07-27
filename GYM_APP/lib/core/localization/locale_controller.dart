import 'dart:ui';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
class LocaleController extends GetxController {
  static const _prefsKey = 'app_locale';

  static const Locale english = Locale('en', 'US');
  static const Locale arabic = Locale('ar', 'SA');

  final Rx<Locale> locale = english.obs;

  bool get isArabic => locale.value.languageCode == 'ar';
  static Future<Locale> resolveInitialLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == 'ar') return arabic;
    if (saved == 'en') return english;

    final systemLanguage = PlatformDispatcher.instance.locale.languageCode;
    return systemLanguage == 'ar' ? arabic : english;
  }

  Future<void> changeLocale(Locale newLocale) async {
    locale.value = newLocale;
    Get.updateLocale(newLocale);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, newLocale.languageCode);
  }

  Future<void> toggleLocale() => changeLocale(isArabic ? english : arabic);
}
