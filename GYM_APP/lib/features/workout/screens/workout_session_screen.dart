import 'dart:async';
import '../services/pending_set_store.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gym_app/core/localization/locale_controller.dart';
import 'package:gym_app/core/theme/app_colors.dart';
import 'package:gym_app/features/exercises/models/exercise.dart';
import 'package:gym_app/features/workout/models/logged_set.dart';
import 'package:gym_app/features/workout/models/workout_session.dart';
import 'package:gym_app/features/workout/screens/workout_summary_screen.dart';
import 'package:gym_app/features/workout/services/workout_service.dart';
import 'package:gym_app/features/workout/widgets/exercise_logging_page.dart';
import 'package:gym_app/features/workout/widgets/rest_timer_banner.dart';
import 'package:gym_app/shared/widgets/animated_tap.dart';
import 'package:gym_app/shared/widgets/app_notification.dart';
import 'package:gym_app/core/theme/responsive.dart';

const int _restDurationSeconds = 90;

/// Active workout screen — one exercise "in focus" per page, swipeable,
/// with a rest timer that runs independently of which page is showing.
class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({
    super.key,
    required this.session,
    required this.exercisesById,
    this.initialSetsBySessionExerciseId = const {},
  });

  final WorkoutSession session;
  final Map<int, Exercise> exercisesById;

  /// Sets already logged before this screen was opened — non-empty only
  /// when resuming an unfinished session (see ResumeWorkout). Seeds both
  /// each exercise page's confirmed-sets list and the overview panel's
  /// progress counts, so a resumed session doesn't look like it's
  /// starting over from zero.
  final Map<int, List<LoggedSet>> initialSetsBySessionExerciseId;

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
  final Set<int> _savingExercises = {};

  // sessionExercise.id -> sets confirmed so far, kept in sync by each
  // ExerciseLoggingPage's onSetLogged callback. Feeds the overview panel
  // so it can show progress without re-fetching anything.
  final Map<int, int> _setsLoggedByExercise = {};

  @override
  void initState() {
    super.initState();
    widget.initialSetsBySessionExerciseId.forEach((sessionExerciseId, sets) {
      if (sets.isNotEmpty)
        _setsLoggedByExercise[sessionExerciseId] = sets.length;
    });
  }

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
    if (_finishing || _savingExercises.isNotEmpty) return;
    setState(() => _finishing = true);
    try {
      final summary = await _workoutService.finishSession(widget.session.id);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WorkoutSummaryScreen(summary: summary),
        ),
      );
    } catch (e) {
      // Logged so the real cause shows in the device console instead of
      // only ever surfacing as an unhelpful generic banner.
      debugPrint('FinishWorkout failed: $e');
      if (mounted) {
        AppNotification.showError(
          context,
          (e is PendingWorkoutSetsException
                  ? 'finish_pending_sets'
                  : 'generic_error')
              .tr,
        );
      }
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  void _jumpToExercise(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _showOverview() {
    final isArabic = Get.find<LocaleController>().isArabic;
    final sessionExercises = widget.session.sessionExercises;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              20.rs(context),
              16.rs(context),
              20.rs(context),
              8.rs(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'session_overview'.tr,
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 17.rf(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: sessionExercises.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final sessionExercise = sessionExercises[index];
                      final exercise =
                          widget.exercisesById[sessionExercise.exerciseId];
                      final setsLogged =
                          _setsLoggedByExercise[sessionExercise.id] ?? 0;
                      final isCurrent = index == _currentIndex;

                      return AnimatedTap(
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _jumpToExercise(index);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.primary.withOpacity(0.12)
                                : AppColors.darkCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCurrent
                                  ? AppColors.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                setsLogged > 0
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                color: setsLogged > 0
                                    ? AppColors.success
                                    : AppColors.textGrey,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  exercise?.localizedName(isArabic) ?? '',
                                  style: TextStyle(
                                    color: AppColors.textWhite,
                                    fontSize: 14.rf(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                setsLogged == 0
                                    ? 'not_started'.tr
                                    : '$setsLogged ${'sets_logged_suffix'.tr}',
                                style: TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 12.rf(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmLeave() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('leave_workout_title'.tr),
        content: Text('leave_workout_message'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'leave'.tr,
              style: const TextStyle(color: AppColors.error),
            ),
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
                padding: EdgeInsetsDirectional.fromSTEB(
                  20.rs(context),
                  12.rs(context),
                  20.rs(context),
                  8.rs(context),
                ),
                child: Row(
                  children: [
                    AnimatedTap(
                      onTap: () async {
                        if (await _confirmLeave() && mounted)
                          Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textGrey,
                          size: 19,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: total == 0
                          ? const SizedBox.shrink()
                          : GestureDetector(
                              onTap: _showOverview,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${'exercise_progress'.tr} ${_currentIndex + 1}/$total',
                                    style: TextStyle(
                                      color: AppColors.textGrey,
                                      fontSize: 13.rf(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.expand_more_rounded,
                                    color: AppColors.textGrey,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                    ),
                    TextButton(
                      onPressed: _finishing || _savingExercises.isNotEmpty
                          ? null
                          : _finishWorkout,
                      child: _finishing
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : Text(
                              'finish_workout'.tr,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14.rf(context),
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
                        child: Text(
                          'exercises_empty'.tr,
                          style: const TextStyle(color: AppColors.textGrey),
                        ),
                      )
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: total,
                        onPageChanged: (index) =>
                            setState(() => _currentIndex = index),
                        itemBuilder: (context, index) {
                          final sessionExercise = sessionExercises[index];
                          final exercise =
                              widget.exercisesById[sessionExercise.exerciseId];
                          if (exercise == null) {
                            return const SizedBox.shrink();
                          }
                          return AbsorbPointer(
                            absorbing: _finishing,
                            child: ExerciseLoggingPage(
                              onSavingChanged: (saving) {
                                if (!mounted) return;
                                setState(() {
                                  if (saving) {
                                    _savingExercises.add(sessionExercise.id);
                                  } else {
                                    _savingExercises.remove(sessionExercise.id);
                                  }
                                });
                              },
                              sessionId: widget.session.id,
                              sessionExercise: sessionExercise,
                              exercise: exercise,
                              initialSets:
                                  widget
                                      .initialSetsBySessionExerciseId[sessionExercise
                                      .id] ??
                                  const [],
                              onSetLogged:
                                  (sessionExerciseId, totalConfirmedSets) {
                                    setState(() {
                                      _setsLoggedByExercise[sessionExerciseId] =
                                          totalConfirmedSets;
                                    });
                                    _startRestTimer();
                                  },
                            ),
                          );
                        },
                      ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1,
                    child: child,
                  ),
                ),
                child: _restSecondsRemaining != null
                    ? RestTimerBanner(
                        key: const ValueKey('rest-timer'),
                        secondsRemaining: _restSecondsRemaining!,
                        totalSeconds: _restDurationSeconds,
                        onSkip: _skipRest,
                      )
                    : (total > 1
                          ? Padding(
                              key: const ValueKey('nav-buttons'),
                              padding: EdgeInsetsDirectional.fromSTEB(
                                20.rs(context),
                                4.rs(context),
                                20.rs(context),
                                16.rs(context),
                              ),
                              child: Row(
                                children: [
                                  _NavButton(
                                    icon: Icons.chevron_left_rounded,
                                    enabled: _currentIndex > 0,
                                    onTap: () => _pageController.previousPage(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                                  const Spacer(),
                                  _NavButton(
                                    icon: Icons.chevron_right_rounded,
                                    enabled: _currentIndex < total - 1,
                                    onTap: () => _pageController.nextPage(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('nav-empty'))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedTap(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Icon(
          icon,
          color: enabled
              ? AppColors.textWhite
              : AppColors.textGrey.withOpacity(0.3),
        ),
      ),
    );
  }
}
