import '../../../core/constant/const.dart';

class MuscleGroup {
  const MuscleGroup({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.media,
  });

  final int id;
  final String nameEn;
  final String nameAr;
  final String? media;

  /// Full, directly-loadable URL for [media], or null if this muscle group
  /// has no image. `media` from the API is a relative storage path (e.g.
  /// `muscle-groups/xyz.jpg`), same convention as the admin panel.
  String? get mediaUrl {
    if (media == null || media!.isEmpty) return null;
    return '$storageBaseUrl/$media';
  }

  String localizedName(bool isArabic) => isArabic ? nameAr : nameEn;

  factory MuscleGroup.fromJson(Map<String, dynamic> json) {
    return MuscleGroup(
      id: json['id'] as int,
      nameEn: json['name_en']?.toString() ?? '',
      nameAr: json['name_ar']?.toString() ?? '',
      media: json['media']?.toString(),
    );
  }
}
