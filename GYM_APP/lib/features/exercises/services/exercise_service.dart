import 'package:dio/dio.dart';
import 'package:gym_app/core/services/api_client.dart';
import '../models/exercise.dart';
import '../models/exercise_last_performance.dart';
import '../models/exercise_progress.dart';
import '../models/muscle_group.dart';

class ExerciseService {
  final _dio = ApiClient.instance.dio;

  Future<List<MuscleGroup>> fetchMuscleGroups() async {
    final response = await _dio.get('/muscle-groups');
    return (response.data as List<dynamic>)
        .map((e) => MuscleGroup.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Exercise>> fetchExercisesForMuscleGroup(int muscleGroupId) async {
    final response = await _dio.get('/muscle-groups/$muscleGroupId/exercises');
    return (response.data as List<dynamic>)
        .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Exercise> fetchExercise(int exerciseId) async {
    try {
      final response = await _dio.get('/exercises/$exerciseId');
      return Exercise.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Distinct from other DioExceptions so callers (e.g. RepeatLastWorkout,
        // which fetches exercises from a possibly-stale past session) can
        // tell "this exercise was deleted since" apart from a network/server
        // failure and show something more specific than a generic error.
        throw ExerciseNotFoundException(exerciseId);
      }
      rethrow;
    }
  }

  /// Never throws for "no history yet" — returns [ExerciseLastPerformance.empty]
  /// instead, since that's a completely normal state (first time doing this
  /// exercise), not an error.
  Future<ExerciseLastPerformance> fetchLastPerformance(int exerciseId) async {
    try {
      final response = await _dio.get('/exercises/$exerciseId/last-performance');
      final data = response.data;
      if (data == null) return ExerciseLastPerformance.empty;
      return ExerciseLastPerformance.fromJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return ExerciseLastPerformance.empty;
      rethrow;
    }
  }

  /// Every past session that included this exercise, oldest first — the
  /// Progress screen's per-exercise strength trend. Unlike
  /// [fetchLastPerformance] this isn't limited to just the most recent one.
  Future<List<ExerciseProgressPoint>> fetchExerciseProgress(int exerciseId) async {
    final response = await _dio.get('/exercises/$exerciseId/progress');
    final raw = response.data as List<dynamic>? ?? const [];
    return raw
        .map((e) => ExerciseProgressPoint.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

/// Thrown by [ExerciseService.fetchExercise] when the requested exercise id
/// no longer exists in the catalog (e.g. deleted from the admin panel after
/// a session referencing it was logged).
class ExerciseNotFoundException implements Exception {
  ExerciseNotFoundException(this.exerciseId);

  final int exerciseId;

  @override
  String toString() => 'Exercise #$exerciseId no longer exists.';
}
