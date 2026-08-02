/// One set from a user's most recent completed session for a given
/// exercise — used purely as reference/pre-fill data, never sent back to
/// the server as-is.
class LastPerformanceSet {
  const LastPerformanceSet({
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.weightUnit,
  });

  final int setNumber;
  final int reps;
  final double weight;
  final String weightUnit;

  factory LastPerformanceSet.fromJson(Map<String, dynamic> json) {
    return LastPerformanceSet(
      setNumber: json['set_number'] as int,
      reps: json['reps'] as int,
      weight: (json['weight'] as num).toDouble(),
      weightUnit: json['weight_unit']?.toString() ?? 'kg',
    );
  }
}

/// The user's last logged session for one exercise. `sets` is empty when
/// they've never logged this exercise before — screens should treat that
/// as "no history yet" rather than an error.
class ExerciseLastPerformance {
  const ExerciseLastPerformance({this.sessionDate, this.sets = const []});

  final DateTime? sessionDate;
  final List<LastPerformanceSet> sets;

  bool get hasHistory => sets.isNotEmpty;

  factory ExerciseLastPerformance.fromJson(Map<String, dynamic> json) {
    final rawDate = json['session_date']?.toString();
    final rawSets = json['sets'] as List<dynamic>? ?? const [];
    return ExerciseLastPerformance(
      sessionDate: rawDate == null ? null : DateTime.tryParse(rawDate),
      sets: rawSets
          .map((e) => LastPerformanceSet.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  static const empty = ExerciseLastPerformance();
}
