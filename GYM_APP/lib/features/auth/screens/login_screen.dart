import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gym_app/core/theme/app_colors.dart';
import 'package:gym_app/core/theme/responsive.dart';
import 'package:gym_app/core/services/auth_service.dart';
import 'package:gym_app/features/home/screens/home_screen.dart';
import 'package:gym_app/features/profile/screens/complete_profile_screen.dart';
import 'package:gym_app/shared/widgets/language_switcher.dart';
import 'package:gym_app/shared/widgets/animated_tap.dart';
import 'package:gym_app/shared/widgets/app_card.dart';
import 'package:gym_app/shared/widgets/app_notification.dart';
import 'package:gym_app/shared/widgets/fade_slide_in.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isGoogleLoading = false;
  bool _isLoginLoading = false;
  final AuthService _authService = AuthService();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showMessage('please_fill_all_fields'.tr);
      return;
    }

    setState(() => _isLoginLoading = true);
    final result = await _authService.loginWithName(username, password);
    if (!mounted) return;
    setState(() => _isLoginLoading = false);

    if (!result.success) {
      _showMessage(result.error!);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => result.profileComplete
            ? const HomeScreen()
            : const CompleteProfileScreen(),
      ),
    );
  }

  void _showMessage(String text) {
    AppNotification.showError(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // ── Background glow ──────────────────────────────────
          Positioned(
            top: -100,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 26.rs(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: size.height * 0.02),

                  // Language switcher
                  const Align(
                    alignment: Alignment.centerRight,
                    child: LanguageSwitcher(),
                  ),

                  SizedBox(height: size.height * 0.04),

                  // Logo
                  FadeSlideIn(
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: AppColors.primaryGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: AppColors.primaryGlow,
                            ),
                            child: const Icon(
                              Icons.fitness_center_rounded,
                              color: AppColors.textWhite,
                              size: 40,
                            ),
                          ),
                          SizedBox(height: 20.rs(context)),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [AppColors.textWhite, Color(0xFFCCCCCC)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds),
                            child: Text(
                              'welcome_back'.tr,
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    color: AppColors.textWhite,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'login_subtitle'.tr,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textGrey,
                                  letterSpacing: 0.1,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.05),

                  // ── Form card ────────────────────────────────
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: AppCard(
                      padding: const EdgeInsets.all(20),
                      color: AppColors.darkSurface,
                      borderColor: AppColors.darkBorder,
                      borderRadius: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Username
                          _buildLabel('username'.tr),
                          const SizedBox(height: 8),
                          _buildTextField(
                            hint: 'johndoe',
                            icon: Icons.alternate_email_rounded,
                            controller: _usernameController,
                          ),

                          SizedBox(height: 16.rs(context)),

                          // Password
                          _buildLabel('password'.tr),
                          const SizedBox(height: 8),
                          _buildTextField(
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            controller: _passwordController,
                            obscure: _obscurePassword,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textGrey,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'forgot_password'.tr,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.rf(context),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 20.rs(context)),

                          // Login button
                          _buildPrimaryButton(
                            label: _isLoginLoading ? 'loading'.tr : 'login'.tr,
                            onTap: _isLoginLoading ? () {} : _handleLogin,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 28.rs(context)),

                  // ── Divider ──────────────────────────────────
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 140),
                    child: Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.darkBorder)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or_continue_with'.tr,
                            style: TextStyle(
                              color: AppColors.textGrey.withOpacity(0.8),
                              fontSize: 12.rf(context),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.darkBorder)),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.rs(context)),

                  // ── Social buttons ───────────────────────────
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 180),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSocialButton(
                            label: _isGoogleLoading ? 'loading'.tr : 'google'.tr,
                            icon: Icons.g_mobiledata,
                            iconColor: const Color(0xFFEA4335),
                            onTap: _isGoogleLoading ? null : () async {
                              setState(() => _isGoogleLoading = true);
                              final success = await _authService.loginWithGoogle();
                              if (!mounted) return;
                              setState(() => _isGoogleLoading = false);
                              if (success) {
                                // TODO: Navigate to home screen
                                AppNotification.showSuccess(context, 'logged_in_google'.tr);
                              } else {
                                AppNotification.showError(context, 'google_login_failed'.tr);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSocialButton(
                            label: 'apple'.tr,
                            icon: Icons.apple,
                            iconColor: AppColors.textWhite,
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32.rs(context)),

                  // Register link
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 220),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'no_account'.tr,
                            style: TextStyle(color: AppColors.textGrey, fontSize: 14.rf(context)),
                          ),
                          AnimatedTap(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Text(
                                'sign_up'.tr,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.rf(context),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 28.rs(context)),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: TextStyle(
          color: AppColors.textWhite,
          fontSize: 15.rf(context),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textGrey, fontSize: 14.rf(context)),
          prefixIcon: Icon(icon, color: AppColors.textGrey, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({required String label, required VoidCallback onTap}) {
    return AnimatedTap(
      onTap: onTap,
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
            label,
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

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return AnimatedTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.rf(context),
                fontWeight: FontWeight.w600,
                color: AppColors.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
