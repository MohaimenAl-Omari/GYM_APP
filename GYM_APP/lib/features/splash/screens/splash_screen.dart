import 'package:flutter/material.dart';
import 'package:gym_app/core/services/auth_service.dart';
import 'package:gym_app/core/theme/app_colors.dart';
import 'package:gym_app/core/theme/responsive.dart';
import 'package:gym_app/features/auth/models/login_result.dart';
import 'package:gym_app/features/auth/screens/login_screen.dart';
import 'package:gym_app/features/home/screens/home_screen.dart';
import 'package:gym_app/features/profile/screens/complete_profile_screen.dart';

/// First screen the app shows. Checks whether a saved session already
/// exists (and is still valid) so a user who logged in before and just
/// closed the app lands straight back on Home instead of the login form.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();

  late final AnimationController _logoController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _logoController,
    curve: Curves.easeOut,
  );
  late final Animation<double> _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
    CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
  );

  @override
  void initState() {
    super.initState();
    _logoController.forward();
    _resolveStartDestination();
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _resolveStartDestination() async {
    final AuthStatus status = await _authService.checkSession();
    if (!mounted) return;

    final Widget destination = switch (status) {
      AuthStatus.home => const HomeScreen(),
      AuthStatus.needsProfile => const CompleteProfileScreen(),
      AuthStatus.loggedOut => const LoginScreen(),
    };

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: FadeTransition(
          opacity: _logoFade,
          child: ScaleTransition(
            scale: _logoScale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
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
                    size: 42,
                  ),
                ),
                SizedBox(height: 24.rs(context)),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
