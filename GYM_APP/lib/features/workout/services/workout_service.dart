import 'package:gym_app/core/services/api_client.dart';
import 'package:dio/dio.dart';
import 'pending_set_store.dart';
import '../models/logged_set.dart';
import '../models/session_exercise.dart';
import '../models/workout_session.dart';
import '../models/workout_history.dart';

class WorkoutService {
  WorkoutService({Dio? dio, PendingSetStore? pendingSets})
    : _dio = dio ?? ApiClient.instance.dio,
      pendingSets = pendingSets ?? PendingSetStore();

  final Dio _dio;
  final PendingSetStore pendingSets;
  static final Map<String, Future<LoggedSet>> _inFlight = {};

  Future<WorkoutSession> startSession({
    required List<int> muscleGroupIds,
    required List<int> exerciseIds,
  }) async {
    final response = await _dio.post(
      '/workout-sessions',
      data: {'muscle_group_ids': muscleGroupIds, 'exercise_ids': exerciseIds},
    );
    return WorkoutSession.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<SessionExercise> addExercise({
    required int sessionId,
    required int exerciseId,
  }) async {
    final response = await _dio.post(
      '/workout-sessions/$sessionId/exercises',
      data: {'exercise_id': exerciseId},
    );
    return SessionExercise.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  /// Retry the original persisted payload if the last response was lost.
  Future<LoggedSet> logSet(int sessionId, LoggedSet set) {
    final key = '$sessionId:${set.sessionExerciseId}';
    return _inFlight.putIfAbsent(
      key,
      () => _persistAndSendSet(sessionId, set).whenComplete(() {
        _inFlight.remove(key);
      }),
    );
  }

  Future<LoggedSet> _persistAndSendSet(int sessionId, LoggedSet set) async {
    final pending = await pendingSets.read(sessionId, set.sessionExerciseId);
    final attempt = pending ?? set;
    await pendingSets.save(sessionId, attempt);
    try {
      final response = await _dio.post(
        '/workout-sessions/$sessionId/sets',
        data: attempt.toJson(),
      );
      final saved = LoggedSet.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      await pendingSets.remove(sessionId, attempt.sessionExerciseId);
      return saved;
    } on DioException catch (error) {
      // Validation failures definitively did not create a set. Ambiguous
      // network/server failures must retain their ID for a safe retry.
      if (error.response?.statusCode == 422) {
        await pendingSets.remove(sessionId, attempt.sessionExerciseId);
      }
      rethrow;
    }
  }

  Future<void> updateSet(int sessionId, int setId, LoggedSet set) async {
    await _dio.put(
      '/workout-sessions/$sessionId/sets/$setId',
      data: set.toJson(),
    );
  }

  Future<void> deleteSet(int sessionId, int setId) async {
    await _dio.delete('/workout-sessions/$sessionId/sets/$setId');
  }

  Future<WorkoutSummary> finishSession(int sessionId, {String? notes}) async {
    if (_inFlight.keys.any((key) => key.startsWith('$sessionId:')) ||
        await pendingSets.hasPending(sessionId)) {
      throw PendingWorkoutSetsException();
    }
    final response = await _dio.put(
      '/workout-sessions/$sessionId/finish',
      data: {if (notes != null && notes.isNotEmpty) 'notes': notes},
    );
    return WorkoutSummary.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  /// History tab's list — every session the user has started, most recent
  /// first, summary only (no per-set data).
  Future<List<WorkoutHistoryItem>> fetchHistory() async {
    final response = await _dio.get('/workout-sessions');
    final raw = response.data as List<dynamic>? ?? const [];
    return raw
        .map(
          (e) =>
              WorkoutHistoryItem.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  /// Full exercise/set breakdown for one past session, shown when a
  /// History list row is tapped.
  Future<WorkoutHistoryDetail> fetchSessionDetail(int sessionId) async {
    final response = await _dio.get('/workout-sessions/$sessionId');
    return WorkoutHistoryDetail.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  /// Edits a past session's notes after the fact — separate from
  /// [finishSession], which only sets notes once at completion time.
  Future<void> updateSessionNotes(int sessionId, String? notes) async {
    await _dio.put('/workout-sessions/$sessionId', data: {'notes': notes});
  }

  /// Deletes a past session and everything logged under it. Irreversible —
  /// callers should confirm with the user before calling this.
  Future<void> deleteSession(int sessionId) async {
    await _dio.delete('/workout-sessions/$sessionId');
  }
}
