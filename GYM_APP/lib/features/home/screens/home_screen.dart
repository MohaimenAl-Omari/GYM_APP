import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/core/services/auth_service.dart';
import 'package:gym_app/core/theme/app_colors.dart';
import 'package:gym_app/core/theme/responsive.dart';
import 'package:gym_app/features/auth/screens/login_screen.dart';
import 'package:gym_app/features/exercises/data/exercise_seed_data.dart';
import 'package:gym_app/features/exercises/screens/exercise_detail_screen.dart';
import 'package:gym_app/features/exercises/screens/exercises_screen.dart';
import 'package:gym_app/features/exercises/services/exercise_service.dart';
import 'package:gym_app/features/workout/screens/start_workout_screen.dart';
import 'package:gym_app/features/workout/screens/history_screen.dart';
import 'package:gym_app/features/workout/services/repeat_last_workout.dart';
import 'package:gym_app/features/workout/services/resume_workout.dart';
import 'package:gym_app/features/workout/services/workout_service.dart';
import 'package:gym_app/features/workout/models/workout_history.dart';
import 'package:gym_app/core/localization/locale_controller.dart';
import 'package:gym_app/features/profile/screens/settings_screen.dart';
import 'package:gym_app/features/progress/screens/progress_screen.dart';
import 'package:gym_app/shared/widgets/language_switcher.dart';
import 'package:gym_app/shared/widgets/app_card.dart';
import 'package:gym_app/shared/widgets/animated_tap.dart';
import 'package:gym_app/shared/widgets/app_notification.dart';
import 'package:gym_app/shared/widgets/fade_slide_in.dart';

/// Main dashboard the user lands on after login/onboarding.
///
/// The stats row is computed client-side from `GET /workout-sessions`
/// (see `_loadStats`) rather than a dedicated backend endpoint — the app
/// doesn't track workout duration server-side, so "Sets this week" is
/// shown instead of "Minutes" (that field only exists on the one-time
/// finish-session summary, not on the history list this screen reads).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final WorkoutService _workoutService = WorkoutService();
  String _userName = '';
  LastWorkoutPreview? _lastWorkout;
  bool _repeating = false;

  // Set instead of _lastWorkout when the most recent session was never
  // finished (app crashed/killed/phone died mid-workout) — offering
  // "Repeat" for a session that's still technically open would start a
  // confusing duplicate instead of picking the real one back up.
  WorkoutHistoryItem? _activeSession;
  bool _resuming = false;

  // Null = still loading (or failed) — rendered as "–" rather than a
  // misleading "0" that would flash before the real number arrives.
  int? _workoutsThisWeek;
  int? _setsThisWeek;
  int? _dayStreak;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadLastWorkout();
    _loadStats();
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
      final active = await RepeatLastWorkout.fetchActiveSession();
      if (!mounted) return;
      setState(() {
        _lastWorkout = preview;
        _activeSession = active;
      });
    } catch (_) {
      // Silently skip the shortcut if this fails — it's a convenience,
      // not something that should block the rest of the home screen.
    }
  }

  Future<void> _resumeWorkout() async {
    if (_activeSession == null || _resuming) return;
    setState(() => _resuming = true);
    try {
      await ResumeWorkout.resume(context, _activeSession!.id);
    } catch (e) {
      debugPrint('ResumeWorkout failed: $e');
      if (mounted) {
        AppNotification.showError(context, 'generic_error'.tr);
      }
    } finally {
      if (mounted) setState(() => _resuming = false);
    }
  }

  /// Monday-anchored start of the calendar week containing [date].
  DateTime _startOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  /// Consecutive-day streak, walking backward from today. If there's no
  /// workout logged yet today, we start counting from yesterday instead —
  /// otherwise everyone's streak would show as broken every morning before
  /// their first set of the day.
  int _computeDayStreak(List<WorkoutHistoryItem> history) {
    final workoutDays = <DateTime>{};
    for (final item in history) {
      final parsed = DateTime.tryParse(item.date);
      if (parsed == null) continue;
      workoutDays.add(DateTime(parsed.year, parsed.month, parsed.day));
    }
    if (workoutDays.isEmpty) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    var cursor = workoutDays.contains(todayDate)
        ? todayDate
        : todayDate.subtract(const Duration(days: 1));

    var streak = 0;
    while (workoutDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<void> _loadStats() async {
    try {
      final history = await _workoutService.fetchHistory();
      final weekStart = _startOfWeek(DateTime.now());

      var workouts = 0;
      var sets = 0;
      for (final item in history) {
        final parsed = DateTime.tryParse(item.date);
        if (parsed == null) continue;
        final day = DateTime(parsed.year, parsed.month, parsed.day);
        if (!day.isBefore(weekStart)) {
          workouts++;
          sets += item.totalSets;
        }
      }

      final streak = _computeDayStreak(history);
      if (!mounted) return;
      setState(() {
        _workoutsThisWeek = workouts;
        _setsThisWeek = sets;
        _dayStreak = streak;
      });
    } catch (_) {
      // Leave the stats row showing "–" — this section is a convenience,
      // not something that should block the rest of the home screen. The
      // user can pull-to-refresh to retry.
    }
  }

  Future<void> _repeatLastWorkout() async {
    if (_lastWorkout == null || _repeating) return;
    setState(() => _repeating = true);
    try {
      await RepeatLastWorkout.start(context, _lastWorkout!.sessionId);
    } catch (e) {
      // Always logged, even in release-adjacent debug runs, so a failure
      // here is diagnosable from the device console instead of only ever
      // showing as an unhelpful generic snackbar.
      debugPrint('RepeatLastWorkout failed: $e');
      if (mounted) {
        final message = (e is RepeatLastWorkoutException || e is ExerciseNotFoundException)
            ? e.toString()
            : 'generic_error'.tr;
        AppNotification.showError(context, message);
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
            await Future.wait([
              _loadUserName(),
              _loadLastWorkout(),
              _loadStats(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsetsDirectional.fromSTEB(
              24.rs(context),
              12.rs(context),
              24.rs(context),
              32.rs(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeSlideIn(child: _buildHeader(firstName)),
                SizedBox(height: 28.rs(context)),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 70),
                  child: _buildStartWorkoutCard(),
                ),
                if (_activeSession != null) ...[
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: _buildResumeWorkoutCard(),
                  ),
                ] else if (_lastWorkout != null) ...[
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: _buildRepeatLastWorkoutCard(),
                  ),
                ],
                SizedBox(height: 28.rs(context)),
                _buildStatsRow(),
                SizedBox(height: 28.rs(context)),
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
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 24.rf(context),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'home_ready_subtitle'.tr,
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14.rf(context),
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
    // 48x48 — the minimum comfortable tap target for a screen used
    // one-handed, often mid-workout (see gym-app-mobile-ui-ux skill).
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
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

  void _openProgress() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProgressScreen()),
    );
  }

  Widget _buildStartWorkoutCard() {
    final radius = BorderRadius.circular(24);
    return AnimatedTap(
      onTap: _openStartWorkout,
      borderRadius: radius,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: radius,
          boxShadow: AppColors.primaryGlow,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.textWhite.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.textWhite,
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
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 18.rf(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'home_start_workout_subtitle'.tr,
                    style: TextStyle(
                      color: AppColors.textWhite.withOpacity(0.9),
                      fontSize: 13.rf(context),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textWhite, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeWorkoutCard() {
    final isArabic = Get.find<LocaleController>().isArabic;
    final label = _activeSession!.muscleGroups
        .map((mg) => mg.localizedName(isArabic))
        .join(isArabic ? '، ' : ', ');

    return AppCard(
      onTap: _resuming ? null : _resumeWorkout,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: AppColors.darkSurface,
      // Warning-toned border to make an unfinished session stand out from
      // the neutral "repeat" card it replaces — this one represents
      // in-progress work the user hasn't wrapped up yet.
      borderColor: AppColors.warning.withOpacity(0.4),
      borderRadius: 18,
      withShadow: false,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.pending_actions_rounded, color: AppColors.warning, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'resume_workout'.tr,
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 14.rf(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label.isNotEmpty ? label : 'resume_workout_subtitle'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textGrey, fontSize: 12.rf(context)),
                ),
              ],
            ),
          ),
          _resuming
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.warning),
                )
              : const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textGrey, size: 14),
        ],
      ),
    );
  }

  Widget _buildRepeatLastWorkoutCard() {
    final isArabic = Get.find<LocaleController>().isArabic;
    final label = _lastWorkout!.label(isArabic);

    return AppCard(
      onTap: _repeating ? null : _repeatLastWorkout,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: AppColors.darkSurface,
      borderColor: AppColors.darkBorder,
      borderRadius: 18,
      withShadow: false,
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
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 14.rf(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (label.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textGrey, fontSize: 12.rf(context)),
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
    );
  }

  Widget _buildStatsRow() {
    final stats = <_HomeStat>[
      _HomeStat(
        icon: Icons.fitness_center_rounded,
        value: _workoutsThisWeek?.toString() ?? '–',
        label: 'home_stat_workouts'.tr,
      ),
      _HomeStat(
        icon: Icons.format_list_numbered_rounded,
        value: _setsThisWeek?.toString() ?? '–',
        label: 'home_stat_sets'.tr,
      ),
      _HomeStat(
        icon: Icons.local_fire_department_rounded,
        value: _dayStreak?.toString() ?? '–',
        label: 'home_stat_streak'.tr,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'home_this_week'.tr,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i != 0) const SizedBox(width: 12),
              Expanded(
                child: FadeSlideIn(
                  delay: Duration(milliseconds: 60 * i),
                  child: _buildStatCard(stats[i]),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(_HomeStat stat) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      color: AppColors.darkSurface,
      borderColor: AppColors.darkBorder,
      borderRadius: 18,
      withShadow: false,
      child: Column(
        children: [
          Icon(stat.icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 8),
          // Numbers are the star here — bold and tabular so the digits
          // don't jitter in width once real data replaces the "–".
          Text(
            stat.value,
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 21.rf(context),
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey, fontSize: 11.rf(context)),
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
        onTap: _openProgress,
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
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12.rs(context),
          crossAxisSpacing: 12.rs(context),
          childAspectRatio: 2.4,
          children: [
            for (var i = 0; i < actions.length; i++)
              FadeSlideIn(
                delay: Duration(milliseconds: 60 * i),
                child: _buildQuickActionCard(actions[i]),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    return AppCard(
      onTap: action.onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: AppColors.darkSurface,
      borderColor: AppColors.darkBorder,
      borderRadius: 16,
      withShadow: false,
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
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 13.rf(context),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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

class _HomeStat {
  const _HomeStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;
}
