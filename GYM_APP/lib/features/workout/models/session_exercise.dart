/// One exercise's slot within a workout session, as returned by the
/// backend when the session is created. `id` here is what the API calls
/// `session_exercise_id` — that's the id used when logging sets, not the
/// raw exercise id.
class SessionExercise {
  const SessionExercise({
    required this.id,
    required this.exerciseId,
    required this.order,
  });

  final int id;
  final int exerciseId;
  final int order;

  factory SessionExercise.fromJson(Map<String, dynamic> json) {
    return SessionExercise(
      id: json['id'] as int,
      exerciseId: json['exercise_id'] as int,
      order: json['order'] as int,
    );
  }
}
