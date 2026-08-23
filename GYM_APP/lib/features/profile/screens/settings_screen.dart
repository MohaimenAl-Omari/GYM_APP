import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gym_app/core/services/auth_service.dart';
import 'package:gym_app/core/services/profile_service.dart';
import 'package:gym_app/core/theme/app_colors.dart';
import 'package:gym_app/core/theme/responsive.dart';
import 'package:gym_app/features/auth/screens/login_screen.dart';
import 'package:gym_app/features/profile/models/goal_option.dart';
import 'package:gym_app/shared/widgets/language_switcher.dart';
import 'package:gym_app/shared/widgets/app_card.dart';
import 'package:gym_app/shared/widgets/app_notification.dart';
import 'package:gym_app/shared/widgets/fade_slide_in.dart';

/// Settings tab — profile summary, editable personal stats (the same
/// fields collected on CompleteProfileScreen), language, and logout.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  late Future<Map<String, dynamic>> _userFuture;

  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  String _weightUnit = 'kg';
  String? _selectedGoal;

  bool _saving = false;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUser();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadUser() async {
    final user = await _authService.fetchCurrentUser();
    _ageController.text = user['age']?.toString() ?? '';
    _weightController.text = user['weight']?.toString() ?? '';
    _heightController.text = user['height']?.toString() ?? '';
    _weightUnit = user['weight_unit']?.toString() ?? 'kg';
    _selectedGoal = user['goal']?.toString();
    return user;
  }

  Future<void> _saveChanges() async {
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

    setState(() => _saving = true);
    final error = await _profileService.completeProfile(
      age: age,
      weight: weight,
      height: height,
      weightUnit: _weightUnit,
      goal: _selectedGoal!,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      AppNotification.showError(context, error);
    } else {
      AppNotification.showSuccess(context, 'profile_updated'.tr);
    }
  }

  Future<void> _handleLogout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showMessage(String text) {
    AppNotification.showError(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Center(
                      child: Text(
                        'generic_error'.tr,
                        style: const TextStyle(color: AppColors.textGrey),
                      ),
                    ),
                  ),
                ],
              );
            }

            final user = snapshot.data ?? const {};

            return SingleChildScrollView(
              padding: EdgeInsetsDirectional.fromSTEB(
                  24.rs(context), 0, 24.rs(context), 32.rs(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  FadeSlideIn(child: _buildProfileCard(user)),
                  SizedBox(height: 24.rs(context)),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('personal_info'.tr),
                        const SizedBox(height: 12),
                        _buildPersonalInfoCard(),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.rs(context)),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('preferences'.tr),
                        const SizedBox(height: 12),
                        _buildPreferencesCard(),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.rs(context)),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('account'.tr),
                        const SizedBox(height: 12),
                        _buildLogoutButton(),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.rs(context)),
                  Center(
                    child: Text(
                      'app_version'.tr,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
          24.rs(context), 12.rs(context), 24.rs(context), 8.rs(context)),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: AppColors.textGrey, size: 19),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'settings_title'.tr,
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 20.rf(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> user) {
    final name = user['name']?.toString() ?? '';
    final username = user['username']?.toString();
    final phone = user['phone_number']?.toString();

    return AppCard(
      padding: const EdgeInsets.all(18),
      color: AppColors.darkSurface,
      borderColor: AppColors.darkBorder,
      borderRadius: 18,
      withShadow: false,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.darkCard,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 16.rf(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if ((username ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '@$username',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13.rf(context)),
                  ),
                ],
                if ((phone ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    phone!,
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13.rf(context)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall,
    );
  }

  Widget _buildPersonalInfoCard() {
    return AppCard(
      padding: const EdgeInsets.all(18),
      color: AppColors.darkSurface,
      borderColor: AppColors.darkBorder,
      borderRadius: 18,
      withShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('age'.tr),
          const SizedBox(height: 8),
          _numberField(controller: _ageController, icon: Icons.cake_outlined, hint: '25'),
          SizedBox(height: 16.rs(context)),
          _fieldLabel('weight'.tr),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _numberField(
                  controller: _weightController,
                  icon: Icons.monitor_weight_outlined,
                  hint: '70',
                  allowDecimal: true,
                ),
              ),
              const SizedBox(width: 10),
              _unitToggle(),
            ],
          ),
          SizedBox(height: 16.rs(context)),
          _fieldLabel('height'.tr),
          const SizedBox(height: 8),
          _numberField(
            controller: _heightController,
            icon: Icons.height_rounded,
            hint: '175',
            allowDecimal: true,
          ),
          SizedBox(height: 16.rs(context)),
          _fieldLabel('goal'.tr),
          const SizedBox(height: 10),
          _goalGrid(),
          SizedBox(height: 20.rs(context)),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _saveChanges,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textWhite),
                    )
                  : Text(
                      'save_changes'.tr,
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 14.rf(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.rf(context),
        fontWeight: FontWeight.w600,
        color: AppColors.textLightGrey,
      ),
    );
  }

  Widget _numberField({
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
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _unitToggle() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['kg', 'lbs'].map((unit) {
          final isSelected = _weightUnit == unit;
          return GestureDetector(
            onTap: () => setState(() => _weightUnit = unit),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
        }).toList(),
      ),
    );
  }

  Widget _goalGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: GoalOption.all.map((option) {
        final isSelected = _selectedGoal == option.value;
        return GestureDetector(
          onTap: () => setState(() => _selectedGoal = option.value),
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

  Widget _buildPreferencesCard() {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: AppColors.darkSurface,
      borderColor: AppColors.darkBorder,
      borderRadius: 18,
      withShadow: false,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'language'.tr,
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 14.rf(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const LanguageSwitcher(),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return AppCard(
      onTap: _loggingOut ? null : _handleLogout,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: AppColors.darkSurface,
      borderColor: AppColors.error.withOpacity(0.4),
      borderRadius: 18,
      withShadow: false,
      child: Row(
        children: [
          const Icon(Icons.logout_rounded, color: AppColors.error, size: 19),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'logout'.tr,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 14.rf(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (_loggingOut)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
            ),
        ],
      ),
    );
  }
}
