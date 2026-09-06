import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gym_app/core/localization/locale_controller.dart';
import 'package:gym_app/core/theme/app_colors.dart';
import 'package:gym_app/core/theme/responsive.dart';
import 'package:gym_app/features/exercises/models/exercise.dart';
import 'package:gym_app/features/exercises/models/muscle_group.dart';
import 'package:gym_app/features/exercises/screens/exercise_detail_screen.dart';
import 'package:gym_app/features/exercises/services/exercise_service.dart';
import 'package:gym_app/shared/widgets/animated_tap.dart';
import 'package:gym_app/shared/widgets/app_card.dart';
import 'package:gym_app/shared/widgets/cached_remote_image.dart';
import 'package:gym_app/shared/widgets/empty_state.dart';
import 'package:gym_app/shared/widgets/fade_slide_in.dart';
import 'package:gym_app/shared/widgets/skeleton_loader.dart';

class MuscleGroupExercisesScreen extends StatefulWidget {
  const MuscleGroupExercisesScreen({super.key, required this.muscleGroup});

  final MuscleGroup muscleGroup;

  @override
  State<MuscleGroupExercisesScreen> createState() =>
      _MuscleGroupExercisesScreenState();
}

class _MuscleGroupExercisesScreenState
    extends State<MuscleGroupExercisesScreen> {
  final ExerciseService _service = ExerciseService();
  late Future<List<Exercise>> _future;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _service.fetchExercisesForMuscleGroup(widget.muscleGroup.id);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Get.find<LocaleController>().isArabic;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                  24.rs(context), 12.rs(context), 24.rs(context), 8.rs(context)),
              child: Row(
                children: [
                  AnimatedTap(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textGrey, size: 19),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.muscleGroup.localizedName(isArabic),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                  24.rs(context), 8.rs(context), 24.rs(context), 8.rs(context)),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
                style: const TextStyle(color: AppColors.textWhite),
                decoration: InputDecoration(
                  hintText: 'search_exercises'.tr,
                  hintStyle: const TextStyle(color: AppColors.textGrey),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textGrey),
                  filled: true,
                  fillColor: AppColors.darkSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.darkBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.darkBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Exercise>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return ListView.separated(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          24.rs(context), 8.rs(context), 24.rs(context), 32.rs(context)),
                      itemCount: 6,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, __) => const SkeletonCard(height: 72, margin: EdgeInsets.zero),
                    );
                  }
                  if (snapshot.hasError) {
                    return AppEmptyState(
                      icon: Icons.error_outline_rounded,
                      message: 'generic_error'.tr,
                    );
                  }
                  final all = snapshot.data ?? const [];
                  final exercises = _query.isEmpty
                      ? all
                      : all
                          .where((e) =>
                              e.nameEn.toLowerCase().contains(_query) ||
                              e.nameAr.toLowerCase().contains(_query))
                          .toList();

                  if (exercises.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.search_off_rounded,
                      message: 'exercises_empty'.tr,
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsetsDirectional.fromSTEB(
                        24.rs(context), 8.rs(context), 24.rs(context), 32.rs(context)),
                    itemCount: exercises.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      return FadeSlideIn(
                        delay: Duration(milliseconds: (60 * index).clamp(0, 400)),
                        child: _ExerciseRow(
                          exercise: exercise,
                          isArabic: isArabic,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ExerciseDetailScreen(exercise: exercise),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.exercise,
    required this.isArabic,
    required this.onTap,
  });

  final Exercise exercise;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            // demoUrl (gif-first, falls back to the static image) — same
            // visual the detail screen leads with, so the list preview
            // isn't a static photo for an exercise that actually has a
            // looping GIF one tap away.
            child: CachedRemoteImage(
              url: exercise.demoUrl,
              width: 48,
              height: 48,
              iconSize: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              exercise.localizedName(isArabic),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
        ],
      ),
    );
  }
}
