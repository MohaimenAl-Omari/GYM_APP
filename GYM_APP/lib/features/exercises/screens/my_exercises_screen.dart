import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gym_app/core/localization/locale_controller.dart';
import 'package:gym_app/core/theme/app_colors.dart';
import 'package:gym_app/core/theme/responsive.dart';
import 'package:gym_app/features/exercises/models/exercise.dart';
import 'package:gym_app/features/exercises/screens/add_edit_exercise_screen.dart';
import 'package:gym_app/features/exercises/screens/exercise_detail_screen.dart';
import 'package:gym_app/features/exercises/services/exercise_service.dart';
import 'package:gym_app/shared/widgets/animated_tap.dart';
import 'package:gym_app/shared/widgets/app_card.dart';
import 'package:gym_app/shared/widgets/cached_remote_image.dart';
import 'package:gym_app/shared/widgets/empty_state.dart';
import 'package:gym_app/shared/widgets/fade_slide_in.dart';
import 'package:gym_app/shared/widgets/skeleton_loader.dart';

/// Every exercise the current user has added themselves, across all
/// muscle groups — separate from the official library (ExercisesScreen),
/// per the user's own choice to keep the two lists distinct rather than
/// only surfacing custom exercises inline within each muscle group.
class MyExercisesScreen extends StatefulWidget {
  const MyExercisesScreen({super.key});

  @override
  State<MyExercisesScreen> createState() => _MyExercisesScreenState();
}

class _MyExercisesScreenState extends State<MyExercisesScreen> {
  final ExerciseService _service = ExerciseService();
  late Future<List<Exercise>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchMyExercises();
  }

  Future<void> _reload() async {
    setState(() => _future = _service.fetchMyExercises());
    await _future;
  }

  Future<void> _openAddExercise() async {
    final created = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(builder: (_) => const AddEditExerciseScreen()),
    );
    if (created != null) _reload();
  }

  Future<void> _openDetail(Exercise exercise) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exercise: exercise)),
    );
    // ExerciseDetailScreen pops `true` after a successful edit or delete
    // of a custom exercise — refresh so this list reflects it immediately.
    if (result == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Get.find<LocaleController>().isArabic;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExercise,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: AppColors.textWhite),
      ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'my_exercises'.tr,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          'my_exercises_subtitle'.tr,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textGrey,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.darkSurface,
                onRefresh: _reload,
                child: FutureBuilder<List<Exercise>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return ListView.separated(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            24.rs(context), 8.rs(context), 24.rs(context), 90.rs(context)),
                        itemCount: 6,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, __) => const SkeletonCard(height: 72, margin: EdgeInsets.zero),
                      );
                    }
                    if (snapshot.hasError) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          AppEmptyState(
                            icon: Icons.error_outline_rounded,
                            message: 'generic_error'.tr,
                            actionLabel: 'retry'.tr,
                            onAction: _reload,
                          ),
                        ],
                      );
                    }
                    final exercises = snapshot.data ?? const [];
                    if (exercises.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          AppEmptyState(
                            icon: Icons.fitness_center_rounded,
                            message: 'my_exercises_empty'.tr,
                          ),
                        ],
                      );
                    }
                    return ListView.separated(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          24.rs(context), 8.rs(context), 24.rs(context), 90.rs(context)),
                      itemCount: exercises.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final exercise = exercises[index];
                        return FadeSlideIn(
                          delay: Duration(milliseconds: (60 * index).clamp(0, 400)),
                          child: _MyExerciseRow(
                            exercise: exercise,
                            isArabic: isArabic,
                            onTap: () => _openDetail(exercise),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyExerciseRow extends StatelessWidget {
  const _MyExerciseRow({
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
