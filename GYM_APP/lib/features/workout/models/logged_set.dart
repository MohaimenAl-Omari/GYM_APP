/// A set the user has logged for one exercise in the current session.
/// Mirrors the `sets` table row-for-row.
class LoggedSet {
  LoggedSet({
    this.id,
    required this.sessionExerciseId,
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.weightUnit,
    this.restTime,
  });

  /// Null until the backend confirms the set was saved.
  int? id;
  final int sessionExerciseId;
  final int setNumber;
  int reps;
  double weight;
  String weightUnit;
  int? restTime;

  Map<String, dynamic> toJson() => {
        'session_exercise_id': sessionExerciseId,
        'set_number': setNumber,
        'reps': reps,
        'weight': weight,
        'weight_unit': weightUnit,
        if (restTime != null) 'rest_time': restTime,
      };

  factory LoggedSet.fromJson(Map<String, dynamic> json) {
    return LoggedSet(
      id: json['id'] as int?,
      sessionExerciseId: json['session_exercise_id'] as int,
      setNumber: json['set_number'] as int,
      reps: json['reps'] as int,
      weight: (json['weight'] as num).toDouble(),
      weightUnit: json['weight_unit']?.toString() ?? 'kg',
      restTime: (json['rest_time'] as num?)?.toInt(),
    );
  }
}
