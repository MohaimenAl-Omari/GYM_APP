import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gym_app/core/theme/app_colors.dart';
import 'package:gym_app/core/services/auth_service.dart';
import 'package:gym_app/features/auth/models/login_result.dart';
import 'package:gym_app/features/home/screens/home_screen.dart';
import 'package:gym_app/features/profile/screens/complete_profile_screen.dart';
import 'package:gym_app/shared/widgets/language_switcher.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _isRegisterLoading = false;

  final AuthService _authService = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  static final RegExp _usernamePattern = RegExp(r'^[a-zA-Z0-9_-]+$');

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final phone = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    // Quick client-side checks before hitting the server
    if (name.isEmpty ||
        username.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      _showMessage('please_fill_all_fields'.tr);
      return;
    }
    // Mirrors the backend's `alpha_dash` rule — letters, numbers, dashes
    // and underscores only, no spaces. Catching this here avoids a round
    // trip just to find out the username has a space in it.
    if (!_usernamePattern.hasMatch(username)) {
      _showMessage('invalid_username'.tr);
      return;
    }
    if (password.length < 8) {
      _showMessage('password_min_length'.tr);
      return;
    }
    if (password != confirm) {
      _showMessage('passwords_do_not_match'.tr);
      return;
    }

    setState(() => _isRegisterLoading = true);
    final String? error = await _authService.registerWithPhone(
      name: name,
      username: username,
      phone: phone,
      password: password,
      passwordConfirmation: confirm,
    );
    if (!mounted) return;
    setState(() => _isRegisterLoading = false);

    if (error == null) {
      _goToCompleteProfile();
    } else {
      _showMessage(error);
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isGoogleLoading = true);
    final result = await _authService.signUpWithGoogleAccount();
    if (!mounted) return;
    setState(() => _isGoogleLoading = false);
    _routeAfterSocialAuth(result);
  }

  Future<void> _handleAppleSignUp() async {
    setState(() => _isAppleLoading = true);
    final result = await _authService.signUpWithAppleAccount();
    if (!mounted) return;
    setState(() => _isAppleLoading = false);
    _routeAfterSocialAuth(result);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Manual phone sign-up is always a brand new account, so it always
  /// needs age/weight/height/goal filled in.
  void _goToCompleteProfile() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
    );
  }

  /// Google/Apple double as both "sign up" and "sign in" — if the backend
  /// recognizes the account and it already has age/weight/height/goal
  /// saved, go straight to Home instead of asking for that info again.
  /// A canceled system dialog does nothing (no navigation, no error).
  void _routeAfterSocialAuth(LoginResult result) {
    if (result.canceled) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // ── Background glow ──────────────────────────────────
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Back button + language switcher
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: AppColors.darkBorder),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 17,
                            color: AppColors.textWhite,
                          ),
                        ),
                      ),
                      const LanguageSwitcher(),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Header
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFFCCCCCC)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: Text(
                      'create_account'.tr,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'register_subtitle'.tr,
                    style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
                  ),

                  const SizedBox(height: 28),

                  // ── Form card ────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.darkBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('full_name'.tr),
                        const SizedBox(height: 8),
                        _buildTextField(
                          hint: 'John Doe',
                          icon: Icons.person_outline_rounded,
                          controller: _nameController,
                        ),

                        const SizedBox(height: 18),

                        _buildLabel('username'.tr),
                        const SizedBox(height: 8),
                        _buildTextField(
                          hint: 'johndoe',
                          icon: Icons.alternate_email_rounded,
                          controller: _usernameController,
                          keyboardType: TextInputType.visiblePassword,
                        ),

                        const SizedBox(height: 18),

                        _buildLabel('phone_number'.tr),
                        const SizedBox(height: 8),
                        _buildTextField(
                          hint: '07xxxxxxxxx',
                          icon: Icons.phone,
                          controller: _emailController,
                          keyboardType: TextInputType.phone,
                        ),

                        const SizedBox(height: 18),

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
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),

                        const SizedBox(height: 18),

                        _buildLabel('confirm_password'.tr),
                        const SizedBox(height: 8),
                        _buildTextField(
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          controller: _confirmController,
                          obscure: _obscureConfirm,
                          suffix: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textGrey,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),

                        const SizedBox(height: 24),

                        _buildPrimaryButton(
                          label: _isRegisterLoading
                              ? 'creating_account'.tr
                              : 'create_account'.tr,
                          onTap: _isRegisterLoading ? () {} : _handleRegister,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Divider ──────────────────────────────────
                  Row(
                    children: [
                      const Expanded(
                          child: Divider(color: AppColors.darkBorder)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'or_sign_up_with'.tr,
                          style: TextStyle(
                            color: AppColors.textGrey.withOpacity(0.8),
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const Expanded(
                          child: Divider(color: AppColors.darkBorder)),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ── Social buttons ───────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _buildSocialButton(
                          label: _isGoogleLoading ? 'loading'.tr : 'google'.tr,
                          icon: Icons.g_mobiledata,
                          iconColor: const Color(0xFFEA4335),
                          onTap: _isGoogleLoading ? null : _handleGoogleSignUp,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildSocialButton(
                          label: _isAppleLoading ? 'loading'.tr : 'apple'.tr,
                          icon: Icons.apple,
                          iconColor: Colors.white,
                          onTap: _isAppleLoading ? null : _handleAppleSignUp,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Login link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'already_have_account'.tr,
                          style:
                              const TextStyle(color: AppColors.textGrey, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'login'.tr,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
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
      style: const TextStyle(
        fontSize: 13,
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
        style: const TextStyle(color: AppColors.textWhite, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.textGrey, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(
      {required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
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
