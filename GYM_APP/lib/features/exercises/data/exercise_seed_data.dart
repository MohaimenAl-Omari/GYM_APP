import '../models/exercise.dart';

/// Hand-seeded exercise content used to preview the "demo GIF + target
/// muscles + instructions" UI before this data is coming from the real
/// backend or a content provider like ExerciseDB.
///
/// Not wired into [ExerciseService] — these are constructed directly and
/// pushed onto [ExerciseDetailScreen] from a demo entry point, so nothing
/// about the real exercise list/backend flow is touched.
class ExerciseSeedData {
  ExerciseSeedData._();

  /// id: -1 is intentionally outside the real backend's id range, so the
  /// "last performance" lookup this screen does on open just falls through
  /// to "no history yet" instead of pointing at a made-up real exercise id.
  static const Exercise benchPress = Exercise(
    id: -1,
    muscleGroupId: -1,
    nameEn: 'Barbell Bench Press',
    nameAr: 'بنش برس بار',
    descriptionEn:
        'Classic compound chest press performed lying on a flat bench with a barbell.',
    descriptionAr: 'تمرين ضغط الصدر الأساسي، يُؤدى مستلقيًا على بنش مستوٍ باستخدام البار.',
    gifUrl: 'https://static.exercisedb.dev/media/EIeI8Vf.gif',
    targetMuscle: 'Pectorals',
    secondaryMuscles: ['Triceps', 'Shoulders'],
    instructions: [
      'Lie flat on the bench with feet firmly planted on the ground.',
      'Grip the bar slightly wider than shoulder-width.',
      'Unrack the bar and lower it with control to mid-chest.',
      'Press the bar back up until your arms are fully extended.',
    ],
  );
}
