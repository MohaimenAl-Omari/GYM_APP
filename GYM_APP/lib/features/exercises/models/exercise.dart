import '../../../core/constant/const.dart';

class Exercise {
  const Exercise({
    required this.id,
    required this.muscleGroupId,
    required this.nameEn,
    required this.nameAr,
    this.descriptionEn,
    this.descriptionAr,
    this.media,
  });

  final int id;
  final int muscleGroupId;
  final String nameEn;
  final String nameAr;
  final String? descriptionEn;
  final String? descriptionAr;
  final String? media;

  String? get mediaUrl {
    if (media == null || media!.isEmpty) return null;
    return '$storageBaseUrl/$media';
  }

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
    );
  }
}
