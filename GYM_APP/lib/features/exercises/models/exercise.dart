import '../../../core/utils/media_url.dart';

class Exercise {
  const Exercise({
    required this.id,
    required this.muscleGroupId,
    required this.nameEn,
    required this.nameAr,
    this.descriptionEn,
    this.descriptionAr,
    this.media,
    this.gifUrl,
    this.targetMuscle,
    this.secondaryMuscles = const [],
    this.instructions = const [],
  });

  final int id;
  final int muscleGroupId;
  final String nameEn;
  final String nameAr;
  final String? descriptionEn;
  final String? descriptionAr;
  final String? media;

  /// Looping demo animation (GIF) for this exercise, e.g. from an exercise
  /// content provider like ExerciseDB. Optional — falls back to [media]
  /// (static image) when absent. Seeded exercises set this directly instead
  /// of coming from the backend.
  final String? gifUrl;

  /// Primary muscle this exercise targets (e.g. "Pectoralis Major").
  final String? targetMuscle;

  /// Muscles worked secondarily (e.g. ["Triceps", "Shoulders"]).
  final List<String> secondaryMuscles;

  /// Step-by-step "how to" instructions, shown as a numbered list.
  final List<String> instructions;

  /// `media` can be either a path on this app's own storage or a full
  /// external URL pasted in via the admin panel — [resolveMediaUrl]
  /// detects which and builds the right thing either way.
  String? get mediaUrl => resolveMediaUrl(media);

  String? get _gifUrl => resolveMediaUrl(gifUrl);

  /// The best available demo visual: animated [gifUrl] if present,
  /// otherwise the static [mediaUrl].
  String? get demoUrl => _gifUrl ?? mediaUrl;

  String localizedName(bool isArabic) => isArabic ? nameAr : nameEn;

  String? localizedDescription(bool isArabic) =>
      isArabic ? descriptionAr : descriptionEn;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as int,
      muscleGroupId: json['muscle_group_id'] as int,
      nameEn: json['name_en']?.toString() ?? '',
      nameAr: json['name_ar']?.toString() ?? '',
      descriptionEn: json['description_en']?.toString(),
      descriptionAr: json['description_ar']?.toString(),
      media: json['media']?.toString(),
      gifUrl: json['gif_url']?.toString(),
      targetMuscle: json['target_muscle']?.toString(),
      secondaryMuscles: (json['secondary_muscles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      instructions: (json['instructions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
