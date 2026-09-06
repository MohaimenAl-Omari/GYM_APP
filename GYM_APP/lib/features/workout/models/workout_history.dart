import '../../../core/utils/media_url.dart';

/// A muscle group tag as returned inside a history session summary —
/// intentionally lighter than the full `MuscleGroup` model (no `media`),
/// since the History list only ever shows the name as a chip.
class HistoryMuscleGroup {
  const HistoryMuscleGroup({
    required this.id,
    required this.nameEn,
    required this.nameAr,
  });

  final int id;
  final String nameEn;
  final String nameAr;

  String localizedName(bool isArabic) => isArabic ? nameAr : nameEn;

  factory HistoryMuscleGroup.fromJson(Map<String, dynamic> json) {
    return HistoryMuscleGroup(
      id: json['id'] as int,
      nameEn: json['name_en']?.toString() ?? '',
      nameAr: json['name_ar']?.toString() ?? '',
    );
  }
}

/// One row in the History tab's list — a past workout session with just
/// enough totals to render a card, no per-set data. Mirrors
/// `GET /workout-sessions`.
class WorkoutHistoryItem {
  const WorkoutHistoryItem({
    required this.id,
    required this.date,
    required this.muscleGroups,
    required this.exerciseCount,
    required this.totalSets,
    required this.totalVolume,
    this.durationSeconds,
  });

  final int id;
  final String date;
  final List<HistoryMuscleGroup> muscleGroups;
  final int exerciseCount;
  final int totalSets;
  final double totalVolume;

  /// Null for sessions started before this was tracked, or (in principle)
  /// one that was never finished — there's no separate "in progress"
  /// status field, so null doubles as that signal.
  final int? durationSeconds;

  factory WorkoutHistoryItem.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['muscle_groups'] as List<dynamic>? ?? const [];
    return WorkoutHistoryItem(
      id: json['id'] as int,
      date: json['date']?.toString() ?? '',
      muscleGroups: rawGroups
          .map((e) => HistoryMuscleGroup.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      exerciseCount: (json['exercise_count'] as num?)?.toInt() ?? 0,
      totalSets: (json['total_sets'] as num?)?.toInt() ?? 0,
      totalVolume: (json['total_volume'] as num?)?.toDouble() ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
    );
  }
}

/// One logged set inside a History detail exercise. Distinct from
/// `LoggedSet` (used while actively logging) since this is read-only
/// history data — no `toJson()`/mutation needed.
class HistorySet {
  const HistorySet({
    required this.id,
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.weightUnit,
    this.restTime,
  });

  final int id;
  final int setNumber;
  final int reps;
  final double weight;
  final String weightUnit;
  final int? restTime;

  factory HistorySet.fromJson(Map<String, dynamic> json) {
    return HistorySet(
      id: json['id'] as int,
      setNumber: json['set_number'] as int,
      reps: json['reps'] as int,
      weight: (json['weight'] as num).toDouble(),
      weightUnit: json['weight_unit']?.toString() ?? 'kg',
      restTime: (json['rest_time'] as num?)?.toInt(),
    );
  }
}

/// One exercise (with all its sets) inside a History detail session.
class HistoryExercise {
  const HistoryExercise({
    required this.sessionExerciseId,
    required this.exerciseId,
    required this.nameEn,
    required this.nameAr,
    required this.order,
    required this.sets,
    this.gifUrl,
    this.media,
  });

  final int sessionExerciseId;
  final int exerciseId;
  final String nameEn;
  final String nameAr;
  final int order;
  final List<HistorySet> sets;
  final String? gifUrl;
  final String? media;

  String localizedName(bool isArabic) => isArabic ? nameAr : nameEn;

  String? get _mediaUrl => resolveMediaUrl(media);

  String? get _resolvedGifUrl => resolveMediaUrl(gifUrl);

  /// Same fallback chain as `Exercise.demoUrl`: animated gif if present,
  /// otherwise the static media image.
  String? get demoUrl => _resolvedGifUrl ?? _mediaUrl;

  factory HistoryExercise.fromJson(Map<String, dynamic> json) {
    final rawSets = json['sets'] as List<dynamic>? ?? const [];
    return HistoryExercise(
      sessionExerciseId: json['session_exercise_id'] as int,
      exerciseId: json['exercise_id'] as int,
      nameEn: json['name_en']?.toString() ?? '',
      nameAr: json['name_ar']?.toString() ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      gifUrl: json['gif_url']?.toString(),
      media: json['media']?.toString(),
      sets: rawSets
          .map((e) => HistorySet.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

/// Full breakdown for one past session — `GET /workout-sessions/{id}`.
class WorkoutHistoryDetail {
  const WorkoutHistoryDetail({
    required this.id,
    required this.date,
    required this.muscleGroups,
    required this.totalSets,
    required this.totalVolume,
    required this.exercises,
    this.notes,
    this.durationSeconds,
  });

  final int id;
  final String date;
  final List<HistoryMuscleGroup> muscleGroups;
  final int totalSets;
  final double totalVolume;
  final List<HistoryExercise> exercises;
  final String? notes;
  final int? durationSeconds;

  factory WorkoutHistoryDetail.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['muscle_groups'] as List<dynamic>? ?? const [];
    final rawExercises = json['exercises'] as List<dynamic>? ?? const [];
    return WorkoutHistoryDetail(
      id: json['id'] as int,
      date: json['date']?.toString() ?? '',
      notes: json['notes']?.toString(),
      muscleGroups: rawGroups
          .map((e) => HistoryMuscleGroup.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      totalSets: (json['total_sets'] as num?)?.toInt() ?? 0,
      totalVolume: (json['total_volume'] as num?)?.toDouble() ?? 0,
      exercises: rawExercises
          .map((e) => HistoryExercise.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
    );
  }
}
