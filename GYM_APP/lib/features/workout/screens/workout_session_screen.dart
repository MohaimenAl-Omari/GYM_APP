import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gym_app/core/theme/app_colors.dart';
import 'package:gym_app/features/exercises/models/exercise.dart';
import 'package:gym_app/features/workout/models/workout_session.dart';
import 'package:gym_app/features/workout/screens/workout_summary_screen.dart';
import 'package:gym_app/features/workout/services/workout_service.dart';
import 'package:gym_app/features/workout/widgets/exercise_logging_page.dart';
import 'package:gym_app/features/workout/widgets/rest_timer_banner.dart';

const int _restDurationSeconds = 90;

/// Active workout screen — one exercise "in focus" per page, swipeable,
/// with a rest timer that runs independently of which page is showing.
class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({
    super.key,
    required this.session,
    required this.exercisesById,
  });

  final WorkoutSession session;
  final Map<int, Exercise> exercisesById;

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  final WorkoutService _workoutService = WorkoutService();
  final PageController _pageController = PageController();

  int _currentIndex = 0;
  Timer? _restTimer;
  int? _restSecondsRemaining;
  bool _finishing = false;

  @override
  void dispose() {
    _restTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    setState(() => _restSecondsRemaining = _restDurationSeconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        final remaining = (_restSecondsRemaining ?? 1) - 1;
        if (remaining <= 0) {
          _restSecondsRemaining = null;
          timer.cancel();
        } else {
          _restSecondsRemaining = remaining;
        }
      });
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() => _restSecondsRemaining = null);
  }

  Future<void> _finishWorkout() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      final summary = await _workoutService.finishSession(widget.session.id);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => WorkoutSummaryScreen(summary: summary)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('generic_error'.tr)),
        );
      }
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  Future<bool> _confirmLeave() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text('leave_workout_title'.tr, style: const TextStyle(color: AppColors.textWhite)),
        content: Text(
          'leave_workout_message'.tr,
          style: const TextStyle(color: AppColors.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('leave'.tr, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final sessionExercises = widget.session.sessionExercises;
    final total = sessionExercises.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (await _confirmLeave() && mounted) Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: const Icon(Icons.close_rounded, color: AppColors.textGrey, size: 19),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        total == 0
                            ? ''
                            : '${'exercise_progress'.tr} ${_currentIndex + 1}/$total',
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _finishing ? null : _finishWorkout,
                      child: _finishing
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.primary),
                            )
                          : Text(
                              'finish_workout'.tr,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: total == 0
                    ? Center(
                        child: Text('exercises_empty'.tr,
                            style: const TextStyle(color: AppColors.textGrey)),
                      )
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: total,
                        onPageChanged: (index) => setState(() => _currentIndex = index),
                        itemBuilder: (context, index) {
                          final sessionExercise = sessionExercises[index];
                          final exercise = widget.exercisesById[sessionExercise.exerciseId];
                          if (exercise == null) {
                            return const SizedBox.shrink();
                          }
                          return ExerciseLoggingPage(
                            sessionId: widget.session.id,
                            sessionExercise: sessionExercise,
                            exercise: exercise,
                            onSetLogged: _startRestTimer,
                          );
                        },
                      ),
              ),
              if (_restSecondsRemaining != null)
                RestTimerBanner(
                  secondsRemaining: _restSecondsRemaining!,
                  totalSeconds: _restDurationSeconds,
                  onSkip: _skipRest,
                )
              else if (total > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Row(
                    children: [
                      _NavButton(
                        icon: Icons.chevron_left_rounded,
                        enabled: _currentIndex > 0,
                        onTap: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        ),
                      ),
                      const Spacer(),
                      _NavButton(
                        icon: Icons.chevron_right_rounded,
                        enabled: _currentIndex < total - 1,
                        onTap: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.enabled, required this.onTap});

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.textWhite : AppColors.textGrey.withOpacity(0.3),
        ),
      ),
    );
  }
}
