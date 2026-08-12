import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constant/const.dart';
import '../models/logged_set.dart';
import '../models/session_exercise.dart';
import '../models/workout_session.dart';
import '../models/workout_history.dart';

class WorkoutService {
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

  Future<WorkoutSession> startSession({
    required List<int> muscleGroupIds,
    required List<int> exerciseIds,
  }) async {
    final response = await _dio.post(
      '/workout-sessions',
      data: {
        'muscle_group_ids': muscleGroupIds,
        'exercise_ids': exerciseIds,
      },
      options: await _authOptions(),
    );
    return WorkoutSession.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<SessionExercise> addExercise({
    required int sessionId,
    required int exerciseId,
  }) async {
    final response = await _dio.post(
      '/workout-sessions/$sessionId/exercises',
      data: {'exercise_id': exerciseId},
      options: await _authOptions(),
    );
    return SessionExercise.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// Saves a set the instant the user confirms it — no batching, so
  /// nothing is lost if the app is closed or the phone locks mid-workout.
  Future<LoggedSet> logSet(int sessionId, LoggedSet set) async {
    final response = await _dio.post(
      '/workout-sessions/$sessionId/sets',
      data: set.toJson(),
      options: await _authOptions(),
    );
    return LoggedSet.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> updateSet(int sessionId, int setId, LoggedSet set) async {
    await _dio.put(
      '/workout-sessions/$sessionId/sets/$setId',
      data: set.toJson(),
      options: await _authOptions(),
    );
  }

  Future<void> deleteSet(int sessionId, int setId) async {
    await _dio.delete(
      '/workout-sessions/$sessionId/sets/$setId',
      options: await _authOptions(),
    );
  }

  Future<WorkoutSummary> finishSession(int sessionId, {String? notes}) async {
    final response = await _dio.put(
      '/workout-sessions/$sessionId/finish',
      data: {if (notes != null && notes.isNotEmpty) 'notes': notes},
      options: await _authOptions(),
    );
    return WorkoutSummary.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// History tab's list — every session the user has started, most recent
  /// first, summary only (no per-set data).
  Future<List<WorkoutHistoryItem>> fetchHistory() async {
    final response = await _dio.get(
      '/workout-sessions',
      options: await _authOptions(),
    );
    final raw = response.data as List<dynamic>? ?? const [];
    return raw
        .map((e) => WorkoutHistoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Full exercise/set breakdown for one past session, shown when a
  /// History list row is tapped.
  Future<WorkoutHistoryDetail> fetchSessionDetail(int sessionId) async {
    final response = await _dio.get(
      '/workout-sessions/$sessionId',
      options: await _authOptions(),
    );
    return WorkoutHistoryDetail.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}
