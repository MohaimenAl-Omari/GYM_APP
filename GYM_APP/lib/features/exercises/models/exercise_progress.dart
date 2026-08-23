/// One set within one past session, as returned by
/// `GET /exercises/{id}/progress`. Deliberately its own small model
/// (rather than reusing HistorySet) so the Progress feature doesn't
/// couple to History's model shape.
class ProgressSet {
  const ProgressSet({required this.reps, required this.weight, required this.weightUnit});

  final int reps;
  final double weight;
  final String weightUnit;

  factory ProgressSet.fromJson(Map<String, dynamic> json) {
    return ProgressSet(
      reps: json['reps'] as int,
      weight: (json['weight'] as num).toDouble(),
      weightUnit: json['weight_unit']?.toString() ?? 'kg',
    );
  }
}

/// One past session's sets for a single exercise, oldest-to-newest as
/// returned by `GET /exercises/{id}/progress` — the data behind the
/// Progress screen's per-exercise strength trend.
class ExerciseProgressPoint {
  const ExerciseProgressPoint({
    required this.sessionId,
    required this.date,
    required this.sets,
  });

  final int sessionId;
  final String date;
  final List<ProgressSet> sets;

  /// The heaviest single set logged that session — the standard "how
  /// strong was I that day" number for a strength trend line.
  double get topWeight =>
      sets.isEmpty ? 0 : sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);

  factory ExerciseProgressPoint.fromJson(Map<String, dynamic> json) {
    final rawSets = json['sets'] as List<dynamic>? ?? const [];
    return ExerciseProgressPoint(
      sessionId: json['session_id'] as int,
      date: json['date']?.toString() ?? '',
      sets: rawSets
          .map((e) => ProgressSet.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
