import 'package:dio/dio.dart';
import 'package:gym_app/core/services/api_client.dart';
import '../models/exercise.dart';
import '../models/exercise_last_performance.dart';
import '../models/exercise_progress.dart';
import '../models/muscle_group.dart';

/// Draft fields for [ExerciseService.createExercise]/[ExerciseService.updateExercise]
/// — see docs/exercise-workout-api.md ("User-created exercises"). [photoPath]
/// is a local file path from image_picker; [removePhoto] only matters for
/// an update (clears an existing photo without replacing it).
class ExerciseDraft {
  const ExerciseDraft({
    required this.muscleGroupId,
    required this.name,
    this.description,
    this.photoPath,
    this.removePhoto = false,
  });

  final int muscleGroupId;
  final String name;
  final String? description;
  final String? photoPath;
  final bool removePhoto;
}

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

  /// Every exercise the current user created themselves — the "My
  /// Exercises" screen. Never includes official (admin-curated) ones.
  Future<List<Exercise>> fetchMyExercises() async {
    final response = await _dio.get('/my-exercises');
    return (response.data as List<dynamic>)
        .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Throws [DioException] on failure — callers read
  /// `e.response?.data['message']` for a server-provided reason (e.g. a
  /// validation error) same as the rest of this app's forms.
  Future<Exercise> createExercise(ExerciseDraft draft) async {
    final response = await _dio.post('/exercises', data: await _formData(draft));
    return Exercise.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// See routes/api.php — sent as POST with a spoofed `_method=PUT` field
  /// rather than a real PUT request, because PHP doesn't populate
  /// `$_FILES` on a real multipart PUT (a well-known Laravel/PHP gotcha,
  /// not a bug here). Throws [DioException] on failure, same as [createExercise].
  Future<Exercise> updateExercise(int exerciseId, ExerciseDraft draft) async {
    final formData = await _formData(draft);
    formData.fields.add(const MapEntry('_method', 'PUT'));
    final response = await _dio.post('/exercises/$exerciseId', data: formData);
    return Exercise.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// Returns an error message on failure (notably a 422 when the exercise
  /// has already been logged in a workout — the backend refuses to break
  /// existing history), or `null` on success. Mirrors this app's other
  /// "return the error string, don't throw" service methods.
  Future<String?> deleteExercise(int exerciseId) async {
    try {
      await _dio.delete('/exercises/$exerciseId');
      return null;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return 'Could not connect to the server. Please try again.';
    }
  }

  Future<FormData> _formData(ExerciseDraft draft) async {
    return FormData.fromMap({
      'muscle_group_id': draft.muscleGroupId,
      'name': draft.name,
      if (draft.description != null) 'description': draft.description,
      if (draft.photoPath != null)
        'photo': await MultipartFile.fromFile(draft.photoPath!),
      if (draft.removePhoto) 'remove_photo': true,
    });
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
