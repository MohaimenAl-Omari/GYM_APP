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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('generic_error'.tr)),
        );
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
              padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 24, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
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
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_lastWorkout != null) ...[
                      _RepeatLastWorkoutBanner(
                        preview: _lastWorkout!,
                        loading: _repeating,
                        onTap: _repeatLastWorkout,
                      ),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      'choose_muscle_groups'.tr,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
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
                          children: groups.map((group) {
                            final selected = _selectedGroupIds.contains(group.id);
                            return GestureDetector(
                              onTap: () => _toggleGroup(group),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                                    color: selected ? Colors.white : AppColors.textGrey,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    if (_selectedGroupIds.isNotEmpty) ...[
                      Text(
                        'choose_exercises'.tr,
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
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
                          children: exercises.map((exercise) {
                            final selected = _selectedExerciseIds.contains(exercise.id);
                            return GestureDetector(
                              onTap: () => _toggleExercise(exercise.id),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.darkSurface,
                                  borderRadius: BorderRadius.circular(14),
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
                                        style: const TextStyle(
                                          color: AppColors.textWhite,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
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
                padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 12),
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
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _selectedExerciseIds.isEmpty
                                ? 'home_start_workout'.tr
                                : '${'home_start_workout'.tr} (${_selectedExerciseIds.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
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

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withOpacity(0.4)),
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
