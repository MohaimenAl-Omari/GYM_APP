import 'package:flutter/material.dart';
import '../../exercises/services/exercise_service.dart';
import '../models/logged_set.dart';
import '../models/session_exercise.dart';
import '../models/workout_session.dart';
import '../screens/workout_session_screen.dart';
import 'workout_service.dart';

/// Picks a genuinely unfinished session (see
/// RepeatLastWorkout.fetchActiveSession) back up exactly where it was left
/// — unlike RepeatLastWorkout.start, which begins a brand-new session, this
/// re-enters the *same* session id with every set already logged still in
/// place. That matters for two reasons: the user doesn't lose what they
/// already did, and new sets confirmed after resuming get the correct next
/// set_number instead of colliding with ones already saved server-side.
class ResumeWorkout {
  ResumeWorkout._();

  static final WorkoutService _workoutService = WorkoutService();
  static final ExerciseService _exerciseService = ExerciseService();

  static Future<void> resume(BuildContext context, int sessionId) async {
    final detail = await _workoutService.fetchSessionDetail(sessionId);

    final sessionExercises = detail.exercises
        .map((e) => SessionExercise(id: e.sessionExerciseId, exerciseId: e.exerciseId, order: e.order))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final exercises = await Future.wait(
      sessionExercises.map((se) => _exerciseService.fetchExercise(se.exerciseId)),
    );
    final exercisesById = {for (final exercise in exercises) exercise.id: exercise};

    final initialSetsBySessionExerciseId = <int, List<LoggedSet>>{
      for (final historyExercise in detail.exercises)
        historyExercise.sessionExerciseId: historyExercise.sets
            .map((s) => LoggedSet(
                  id: s.id,
                  sessionExerciseId: historyExercise.sessionExerciseId,
                  setNumber: s.setNumber,
                  reps: s.reps,
                  weight: s.weight,
                  weightUnit: s.weightUnit,
                  restTime: s.restTime,
                ))
            .toList(),
    };

    final session = WorkoutSession(
      id: detail.id,
      date: detail.date,
      sessionExercises: sessionExercises,
    );

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutSessionScreen(
          session: session,
          exercisesById: exercisesById,
          initialSetsBySessionExerciseId: initialSetsBySessionExerciseId,
        ),
      ),
    );
  }
}
