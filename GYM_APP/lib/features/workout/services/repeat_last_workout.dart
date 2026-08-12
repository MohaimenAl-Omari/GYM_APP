import 'package:flutter/material.dart';
import '../../exercises/services/exercise_service.dart';
import '../models/workout_history.dart';
import '../screens/workout_session_screen.dart';
import 'workout_service.dart';

/// A lightweight pointer to the user's most recent session — just enough
/// to render "Repeat: Chest, Back" without fetching every exercise yet.
class LastWorkoutPreview {
  const LastWorkoutPreview({required this.sessionId, required this.muscleGroups});

  final int sessionId;
  final List<HistoryMuscleGroup> muscleGroups;

  String label(bool isArabic) =>
      muscleGroups.map((mg) => mg.localizedName(isArabic)).join(isArabic ? '، ' : ', ');
}

/// "Repeat Last Workout" — shared by the Home screen shortcut and the
/// Start Workout screen's banner. Clones the most recent session's exact
/// muscle groups + exercises so a returning user skips the picker
/// entirely and lands straight in the logging screen.
class RepeatLastWorkout {
  RepeatLastWorkout._();

  static final WorkoutService _workoutService = WorkoutService();
  static final ExerciseService _exerciseService = ExerciseService();

  /// Null if the user has no workout history yet — callers should hide
  /// the shortcut in that case rather than showing an empty/broken state.
  static Future<LastWorkoutPreview?> fetchPreview() async {
    final history = await _workoutService.fetchHistory();
    if (history.isEmpty) return null;
    final latest = history.first;
    return LastWorkoutPreview(sessionId: latest.id, muscleGroups: latest.muscleGroups);
  }

  /// Starts a brand-new session with the same muscle groups + exercises as
  /// [templateSessionId], then pushes straight into the logging screen.
  static Future<void> start(BuildContext context, int templateSessionId) async {
    final detail = await _workoutService.fetchSessionDetail(templateSessionId);
    final muscleGroupIds = detail.muscleGroups.map((mg) => mg.id).toList();
    // sessionExercises is already ordered by `order` server-side (see
    // WorkoutSession::sessionExercises relation) — preserving that order
    // here is what makes the new session's exercise order match the old one.
    final exerciseIds = detail.exercises.map((e) => e.exerciseId).toList();

    final exercises = await Future.wait(
      exerciseIds.map((id) => _exerciseService.fetchExercise(id)),
    );
    final exercisesById = {for (final exercise in exercises) exercise.id: exercise};

    final session = await _workoutService.startSession(
      muscleGroupIds: muscleGroupIds,
      exerciseIds: exerciseIds,
    );

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutSessionScreen(session: session, exercisesById: exercisesById),
      ),
    );
  }
}
