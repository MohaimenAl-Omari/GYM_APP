import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';

/// Small pill button that toggles between English and Arabic. Shows the
/// language you'd switch *to*, not the current one.
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LocaleController>();

    return Obx(
      () => GestureDetector(
        onTap: controller.toggleLocale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language, size: 16, color: AppColors.textGrey),
              const SizedBox(width: 6),
              Text(
                controller.isArabic ? 'English' : 'العربية',
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
