import 'package:flutter/material.dart';
import 'package:gym_app/core/services/auth_service.dart';
import 'package:gym_app/core/theme/app_colors.dart';
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

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _resolveStartDestination();
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
    return const Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
