import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gym_app/core/localization/locale_controller.dart';
import 'package:gym_app/core/theme/app_colors.dart';
import 'package:gym_app/features/exercises/models/exercise.dart';
import 'package:gym_app/features/exercises/models/muscle_group.dart';
import 'package:gym_app/features/exercises/services/exercise_service.dart';
import 'package:gym_app/features/workout/screens/workout_session_screen.dart';
import 'package:gym_app/features/workout/services/workout_service.dart';
import 'package:gym_app/features/workout/services/repeat_last_workout.dart';
import 'package:gym_app/shared/widgets/animated_tap.dart';
import 'package:gym_app/shared/widgets/app_notification.dart';
import 'package:gym_app/shared/widgets/fade_slide_in.dart';
import 'package:gym_app/core/theme/responsive.dart';

/// Pick muscle group(s) -> pick exercises -> start logging. Exercise
/// selection order is preserved and sent to the backend as the session's
/// exercise order (see docs/exercise-workout-api.md).
class StartWorkoutScreen extends StatefulWidget {
  const StartWorkoutScreen({super.key});

  @override
  State<StartWorkoutScreen> createState() => _StartWorkoutScreenState();
}

class _StartWorkoutScreenState extends State<StartWorkoutScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  final WorkoutService _workoutService = WorkoutService();

  late Future<List<MuscleGroup>> _groupsFuture;
  final Set<int> _selectedGroupIds = {};
  final Map<int, List<Exercise>> _exercisesByGroup = {};
  final Set<int> _loadingGroups = {};

  // Insertion order matters — it becomes the session's exercise order.
  final List<int> _selectedExerciseIds = [];
  final Map<int, Exercise> _exercisesById = {};

  bool _starting = false;
  LastWorkoutPreview? _lastWorkout;
  bool _repeating = false;

  @override
  void initState() {
    super.initState();
    _groupsFuture = _exerciseService.fetchMuscleGroups();
    _loadLastWorkout();
  }

  Future<void> _loadLastWorkout() async {
    try {
      final preview = await RepeatLastWorkout.fetchPreview();
      if (!mounted) return;
      setState(() => _lastWorkout = preview);
    } catch (_) {
      // Convenience shortcut only — a failure here shouldn't block picking
      // exercises manually.
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

  Future<void> _toggleGroup(MuscleGroup group) async {
    setState(() {
      if (_selectedGroupIds.contains(group.id)) {
        _selectedGroupIds.remove(group.id);
      } else {
        _selectedGroupIds.add(group.id);
      }
    });

    if (_selectedGroupIds.contains(group.id) && !_exercisesByGroup.containsKey(group.id)) {
      setState(() => _loadingGroups.add(group.id));
      try {
        final exercises = await _exerciseService.fetchExercisesForMuscleGroup(group.id);
        for (final exercise in exercises) {
          _exercisesById[exercise.id] = exercise;
        }
        if (mounted) {
          setState(() {
            _exercisesByGroup[group.id] = exercises;
            _loadingGroups.remove(group.id);
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loadingGroups.remove(group.id));
      }
    }
  }

  void _toggleExercise(int exerciseId) {
    setState(() {
      if (_selectedExerciseIds.contains(exerciseId)) {
        _selectedExerciseIds.remove(exerciseId);
      } else {
        _selectedExerciseIds.add(exerciseId);
      }
    });
  }

  Future<void> _startWorkout() async {
    if (_selectedExerciseIds.isEmpty || _starting) return;
    setState(() => _starting = true);
    try {
      final session = await _workoutService.startSession(
        muscleGroupIds: _selectedGroupIds.toList(),
        exerciseIds: _selectedExerciseIds,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WorkoutSessionScreen(
            session: session,
            exercisesById: _exercisesById,
          ),
        ),
      );
    } catch (e) {
      // Logged so the real cause shows in the device console instead of
      // only ever surfacing as an unhelpful generic banner.
      debugPrint('StartWorkout failed: $e');
      if (mounted) {
        AppNotification.showError(context, 'generic_error'.tr);
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Get.find<LocaleController>().isArabic;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                  24.rs(context), 12.rs(context), 24.rs(context), 8.rs(context)),
              child: Row(
                children: [
                  AnimatedTap(
                    onTap: () => Navigator.of(context).pop(),
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
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textGrey, size: 19),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'home_start_workout'.tr,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsetsDirectional.fromSTEB(
                    24.rs(context), 8.rs(context), 24.rs(context), 32.rs(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_lastWorkout != null) ...[
                      FadeSlideIn(
                        child: _RepeatLastWorkoutBanner(
                          preview: _lastWorkout!,
                          loading: _repeating,
                          onTap: _repeatLastWorkout,
                        ),
                      ),
                      SizedBox(height: 24.rs(context)),
                    ],
                    Text(
                      'choose_muscle_groups'.tr,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<MuscleGroup>>(
                      future: _groupsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                          );
                        }
                        final groups = snapshot.data ?? const [];
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: groups.asMap().entries.map((entry) {
                            final group = entry.value;
                            final selected = _selectedGroupIds.contains(group.id);
                            return FadeSlideIn(
                              delay: Duration(milliseconds: 40 * entry.key),
                              offset: const Offset(0, 0.15),
                              child: AnimatedTap(
                                onTap: () => _toggleGroup(group),
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected ? AppColors.primary : AppColors.darkSurface,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: selected ? AppColors.primary : AppColors.darkBorder,
                                    ),
                                  ),
                                  child: Text(
                                    group.localizedName(isArabic),
                                    style: TextStyle(
                                      color: selected ? AppColors.textWhite : AppColors.textGrey,
                                      fontSize: 13.rf(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    SizedBox(height: 28.rs(context)),
                    if (_selectedGroupIds.isNotEmpty) ...[
                      Text(
                        'choose_exercises'.tr,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      ..._selectedGroupIds.map((groupId) {
                        final loading = _loadingGroups.contains(groupId);
                        final exercises = _exercisesByGroup[groupId] ?? const [];
                        if (loading) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: exercises.asMap().entries.map((entry) {
                            final exercise = entry.value;
                            final selected = _selectedExerciseIds.contains(exercise.id);
                            return FadeSlideIn(
                              delay: Duration(milliseconds: 40 * entry.key),
                              child: AnimatedTap(
                                onTap: () => _toggleExercise(exercise.id),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkSurface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: selected ? AppColors.primary : AppColors.darkBorder,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        selected
                                            ? Icons.check_circle_rounded
                                            : Icons.circle_outlined,
                                        color: selected ? AppColors.primary : AppColors.textGrey,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          exercise.localizedName(isArabic),
                                          style: TextStyle(
                                            color: AppColors.textWhite,
                                            fontSize: 14.rf(context),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                    24.rs(context), 8.rs(context), 24.rs(context), 12.rs(context)),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _selectedExerciseIds.isEmpty || _starting ? null : _startWorkout,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.darkCard,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _starting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textWhite),
                          )
                        : Text(
                            _selectedExerciseIds.isEmpty
                                ? 'home_start_workout'.tr
                                : '${'home_start_workout'.tr} (${_selectedExerciseIds.length})',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 15.rf(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepeatLastWorkoutBanner extends StatelessWidget {
  const _RepeatLastWorkoutBanner({
    required this.preview,
    required this.loading,
    required this.onTap,
  });

  final LastWorkoutPreview preview;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isArabic = Get.find<LocaleController>().isArabic;
    final label = preview.label(isArabic);

    return AnimatedTap(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.4)),
          boxShadow: AppColors.softShadow,
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
            loading
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
}
