import 'session_exercise.dart';

class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.date,
    required this.sessionExercises,
  });

  final int id;
  final String date;
  final List<SessionExercise> sessionExercises;

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['session_exercises'] as List<dynamic>? ?? const [];
    return WorkoutSession(
      id: json['id'] as int,
      date: json['date']?.toString() ?? '',
      sessionExercises: rawExercises
          .map((e) => SessionExercise.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

/// Summary returned when a session is finished — shown on the wrap-up
/// screen. Computed server-side from data the app already sent, so the
/// app doesn't have to (and shouldn't) total these itself.
class WorkoutSummary {
  const WorkoutSummary({
    required this.sessionId,
    required this.durationSeconds,
    required this.totalSets,
    required this.totalVolume,
  });

  final int sessionId;
  final int durationSeconds;
  final int totalSets;
  final double totalVolume;

  factory WorkoutSummary.fromJson(Map<String, dynamic> json) {
    return WorkoutSummary(
      sessionId: json['id'] as int,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      totalSets: (json['total_sets'] as num?)?.toInt() ?? 0,
      totalVolume: (json['total_volume'] as num?)?.toDouble() ?? 0,
    );
  }
}
