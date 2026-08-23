import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gym_app/core/services/profile_service.dart';
import 'package:gym_app/core/theme/app_colors.dart';
import 'package:gym_app/core/theme/responsive.dart';
import 'package:gym_app/features/home/screens/home_screen.dart';
import 'package:gym_app/features/profile/models/goal_option.dart';
import 'package:gym_app/shared/widgets/language_switcher.dart';
import 'package:gym_app/shared/widgets/animated_tap.dart';
import 'package:gym_app/shared/widgets/app_card.dart';
import 'package:gym_app/shared/widgets/app_notification.dart';
import 'package:gym_app/shared/widgets/fade_slide_in.dart';

/// Mandatory one-time screen shown right after account creation. The
/// user cannot leave (no back button, back gesture disabled) until every
/// field is filled in and saved.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final ProfileService _profileService = ProfileService();

  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  String _weightUnit = 'kg';
  String? _selectedGoal;
  bool _isSaving = false;

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final age = int.tryParse(_ageController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());
    final height = double.tryParse(_heightController.text.trim());

    if (age == null || age < 10 || age > 100) {
      _showMessage('invalid_age'.tr);
      return;
    }
    if (weight == null || weight <= 0) {
      _showMessage('invalid_weight'.tr);
      return;
    }
    if (height == null || height <= 0) {
      _showMessage('invalid_height'.tr);
      return;
    }
    if (_selectedGoal == null) {
      _showMessage('please_select_goal'.tr);
      return;
    }

    setState(() => _isSaving = true);
    final error = await _profileService.completeProfile(
      age: age,
      weight: weight,
      height: height,
      weightUnit: _weightUnit,
      goal: _selectedGoal!,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      _showMessage(error);
    }
  }

  void _showMessage(String text) {
    AppNotification.showError(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Nothing to go back to — this page must be completed.
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 26.rs(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.rs(context)),

                FadeSlideIn(
                  child: const Align(
                    alignment: Alignment.centerRight,
                    child: LanguageSwitcher(),
                  ),
                ),

                SizedBox(height: 20.rs(context)),

                FadeSlideIn(
                  delay: const Duration(milliseconds: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppColors.textWhite, Color(0xFFCCCCCC)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds),
                        child: Text(
                          'complete_profile_title'.tr,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: AppColors.textWhite,
                                letterSpacing: -0.5,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'complete_profile_subtitle'.tr,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textGrey,
                            ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.rs(context)),

                FadeSlideIn(
                  delay: const Duration(milliseconds: 90),
                  child: AppCard(
                    padding: const EdgeInsets.all(20),
                    color: AppColors.darkSurface,
                    borderColor: AppColors.darkBorder,
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('age'.tr),
                        const SizedBox(height: 8),
                        _buildNumberField(
                          controller: _ageController,
                          icon: Icons.cake_outlined,
                          hint: '25',
                        ),

                        SizedBox(height: 16.rs(context)),

                        _buildLabel('weight'.tr),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildNumberField(
                                controller: _weightController,
                                icon: Icons.monitor_weight_outlined,
                                hint: '70',
                                allowDecimal: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildUnitToggle(),
                          ],
                        ),

                        SizedBox(height: 16.rs(context)),

                        _buildLabel('height'.tr),
                        const SizedBox(height: 8),
                        _buildNumberField(
                          controller: _heightController,
                          icon: Icons.height_rounded,
                          hint: '175',
                          allowDecimal: true,
                        ),

                        SizedBox(height: 16.rs(context)),

                        _buildLabel('goal'.tr),
                        const SizedBox(height: 8),
                        _buildGoalGrid(),

                        SizedBox(height: 24.rs(context)),

                        _buildContinueButton(),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 28.rs(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.rf(context),
        fontWeight: FontWeight.w600,
        color: AppColors.textLightGrey,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool allowDecimal = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
        style: TextStyle(color: AppColors.textWhite, fontSize: 15.rf(context)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textGrey, fontSize: 14.rf(context)),
          prefixIcon: Icon(icon, color: AppColors.textGrey, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildUnitToggle() {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildUnitOption('kg'),
          _buildUnitOption('lbs'),
        ],
      ),
    );
  }

  Widget _buildUnitOption(String unit) {
    final isSelected = _weightUnit == unit;
    return AnimatedTap(
      onTap: () => setState(() => _weightUnit = unit),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          unit.tr,
          style: TextStyle(
            color: isSelected ? AppColors.textWhite : AppColors.textGrey,
            fontWeight: FontWeight.w600,
            fontSize: 13.rf(context),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: GoalOption.all.map((option) {
        final isSelected = _selectedGoal == option.value;
        return AnimatedTap(
          onTap: () => setState(() => _selectedGoal = option.value),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.darkBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  option.icon,
                  size: 18,
                  color: isSelected ? AppColors.primary : AppColors.textGrey,
                ),
                const SizedBox(width: 8),
                Text(
                  option.labelKey.tr,
                  style: TextStyle(
                    color: isSelected ? AppColors.textWhite : AppColors.textGrey,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.rf(context),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContinueButton() {
    return AnimatedTap(
      onTap: _isSaving ? null : _handleContinue,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.primaryGlow,
        ),
        child: Center(
          child: Text(
            _isSaving ? 'saving'.tr : 'continue_label'.tr,
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 16.rf(context),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
