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

  /// Null if the user has no workout history yet, or if the most recent
  /// session was never finished — callers should hide the shortcut in
  /// either case. An unfinished session should be resumed (see
  /// ResumeWorkout), not repeated as a brand-new duplicate one.
  static Future<LastWorkoutPreview?> fetchPreview() async {
    final history = await _workoutService.fetchHistory();
    if (history.isEmpty) return null;
    final latest = history.first;
    if (latest.durationSeconds == null) return null;
    return LastWorkoutPreview(sessionId: latest.id, muscleGroups: latest.muscleGroups);
  }

  /// The user's current unfinished session, if any — the most recent
  /// session with no `duration_seconds` recorded yet (see
  /// WorkoutSessionController::finish). Null when the last session was
  /// completed normally or there's no history at all. Used to offer
  /// "Resume Workout" instead of losing progress after a crash, a killed
  /// app, or a dead phone mid-workout.
  static Future<WorkoutHistoryItem?> fetchActiveSession() async {
    final history = await _workoutService.fetchHistory();
    if (history.isEmpty) return null;
    final latest = history.first;
    return latest.durationSeconds == null ? latest : null;
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

    // Both are required, non-empty arrays on the backend (see
    // WorkoutSessionController::store validation) — sending either empty
    // would otherwise 422 with nothing useful surfaced to the user. Fail
    // fast here with a message that actually explains what's wrong instead
    // of a generic "something went wrong".
    if (muscleGroupIds.isEmpty || exerciseIds.isEmpty) {
      throw RepeatLastWorkoutException(
        'That session has no ${exerciseIds.isEmpty ? 'exercises' : 'muscle groups'} '
        'logged, so it can\'t be repeated.',
      );
    }

    final exercises = await Future.wait(
      exerciseIds.map((id) => _exerciseService.fetchExercise(id)),
    );
    final exercisesById = {for (final exercise in exercises) exercise.id: exercise};

    if (exercisesById.length != exerciseIds.toSet().length) {
      // One or more exercises from the template session no longer exist in
      // the catalog (deleted since that session was logged). fetchExercise
      // would already have thrown on the missing one, so in practice this
      // is unreachable today — kept as a guard in case that changes.
      throw RepeatLastWorkoutException(
        'One of the exercises from that session no longer exists.',
      );
    }

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

/// Thrown for "repeat" failures that have a specific, user-relevant
/// explanation — as opposed to network/server errors, which callers should
/// still fall back to a generic error message for.
class RepeatLastWorkoutException implements Exception {
  RepeatLastWorkoutException(this.message);

  final String message;

  @override
  String toString() => message;
}
