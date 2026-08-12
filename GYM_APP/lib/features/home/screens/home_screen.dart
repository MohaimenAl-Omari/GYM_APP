import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/core/services/auth_service.dart';
import 'package:gym_app/core/theme/app_colors.dart';
import 'package:gym_app/features/auth/screens/login_screen.dart';
import 'package:gym_app/features/exercises/data/exercise_seed_data.dart';
import 'package:gym_app/features/exercises/screens/exercise_detail_screen.dart';
import 'package:gym_app/features/exercises/screens/exercises_screen.dart';
import 'package:gym_app/features/workout/screens/start_workout_screen.dart';
import 'package:gym_app/features/workout/screens/history_screen.dart';
import 'package:gym_app/features/workout/services/repeat_last_workout.dart';
import 'package:gym_app/core/localization/locale_controller.dart';
import 'package:gym_app/features/profile/screens/settings_screen.dart';
import 'package:gym_app/shared/widgets/language_switcher.dart';

/// Main dashboard the user lands on after login/onboarding.
///
/// This is the UI shell only — the stats row and quick actions use
/// placeholder data for now. Once the workout/exercise backend endpoints
/// exist, wire this up to real data instead of the placeholders marked
/// below.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  String _userName = '';
  LastWorkoutPreview? _lastWorkout;
  bool _repeating = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadLastWorkout();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    if (!mounted) return;
    setState(() => _userName = name);
  }

  Future<void> _loadLastWorkout() async {
    try {
      final preview = await RepeatLastWorkout.fetchPreview();
      if (!mounted) return;
      setState(() => _lastWorkout = preview);
    } catch (_) {
      // Silently skip the shortcut if this fails — it's a convenience,
      // not something that should block the rest of the home screen.
    }
  }

  Future<void> _repeatLastWorkout() async {
    if (_lastWorkout == null || _repeating) return;
    setState(() => _repeating = true);
    try {
      await RepeatLastWorkout.start(context, _lastWorkout!.sessionId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('generic_error'.tr)),
        );
      }
    } finally {
      if (mounted) setState(() => _repeating = false);
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('home_coming_soon'.tr)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _userName.trim().isEmpty
        ? ''
        : _userName.trim().split(RegExp(r'\s+')).first;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.darkSurface,
          onRefresh: () async {
            // TODO: refresh real stats/sessions once the backend exists.
            await _loadUserName();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(firstName),
                const SizedBox(height: 28),
                _buildStartWorkoutCard(),
                if (_lastWorkout != null) ...[
                  const SizedBox(height: 12),
                  _buildRepeatLastWorkoutCard(),
                ],
                const SizedBox(height: 28),
                _buildStatsRow(),
                const SizedBox(height: 28),
                _buildQuickActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String firstName) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                firstName.isEmpty
                    ? '${'home_hi'.tr} \u{1F44B}'
                    : '${'home_hi'.tr}, $firstName \u{1F44B}',
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'home_ready_subtitle'.tr,
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const LanguageSwitcher(),
        const SizedBox(width: 10),
        _buildIconButton(
          icon: Icons.logout_rounded,
          onTap: _handleLogout,
        ),
      ],
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Icon(icon, color: AppColors.textGrey, size: 19),
      ),
    );
  }

  void _openStartWorkout() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StartWorkoutScreen()),
    );
  }

  void _openExercises() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExercisesScreen()),
    );
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  Widget _buildStartWorkoutCard() {
    return GestureDetector(
      onTap: _openStartWorkout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'home_start_workout'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'home_start_workout_subtitle'.tr,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatLastWorkoutCard() {
    final isArabic = Get.find<LocaleController>().isArabic;
    final label = _lastWorkout!.label(isArabic);

    return GestureDetector(
      onTap: _repeating ? null : _repeatLastWorkout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.replay_rounded, color: AppColors.primary, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'repeat_last_workout'.tr,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (label.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            _repeating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textGrey, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    // Placeholder values — replace with real numbers once there's a
    // workout-sessions endpoint to pull them from.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'home_this_week'.tr,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.fitness_center_rounded,
                value: '0',
                label: 'home_stat_workouts'.tr,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.timer_outlined,
                value: '0',
                label: 'home_stat_minutes'.tr,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_fire_department_rounded,
                value: '0',
                label: 'home_stat_streak'.tr,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.menu_book_rounded,
        labelKey: 'home_exercises',
        onTap: _openExercises,
      ),
      _QuickAction(
        icon: Icons.show_chart_rounded,
        labelKey: 'home_progress',
        onTap: _showComingSoon,
      ),
      _QuickAction(
        icon: Icons.history_rounded,
        labelKey: 'home_history',
        onTap: _openHistory,
      ),
      _QuickAction(
        icon: Icons.person_outline_rounded,
        labelKey: 'home_profile',
        onTap: _openSettings,
      ),

    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'home_quick_actions'.tr,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.4,
          children: actions.map(_buildQuickActionCard).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(action.icon, color: AppColors.primary, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                action.labelKey.tr,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.labelKey,
    required this.onTap,
  });

  final IconData icon;
  final String labelKey;
  final VoidCallback onTap;
}
