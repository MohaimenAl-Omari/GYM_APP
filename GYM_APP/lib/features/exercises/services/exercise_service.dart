import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constant/const.dart';
import '../models/exercise.dart';
import '../models/exercise_last_performance.dart';
import '../models/muscle_group.dart';

class ExerciseService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<Options> _authOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<MuscleGroup>> fetchMuscleGroups() async {
    final response = await _dio.get(
      '/muscle-groups',
      options: await _authOptions(),
    );
    return (response.data as List<dynamic>)
        .map((e) => MuscleGroup.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Exercise>> fetchExercisesForMuscleGroup(int muscleGroupId) async {
    final response = await _dio.get(
      '/muscle-groups/$muscleGroupId/exercises',
      options: await _authOptions(),
    );
    return (response.data as List<dynamic>)
        .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Exercise> fetchExercise(int exerciseId) async {
    final response = await _dio.get(
      '/exercises/$exerciseId',
      options: await _authOptions(),
    );
    return Exercise.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// Never throws for "no history yet" — returns [ExerciseLastPerformance.empty]
  /// instead, since that's a completely normal state (first time doing this
  /// exercise), not an error.
  Future<ExerciseLastPerformance> fetchLastPerformance(int exerciseId) async {
    try {
      final response = await _dio.get(
        '/exercises/$exerciseId/last-performance',
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) return ExerciseLastPerformance.empty;
      return ExerciseLastPerformance.fromJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return ExerciseLastPerformance.empty;
      rethrow;
    }
  }
}
