import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gym_app/core/localization/locale_controller.dart';
import 'package:gym_app/core/theme/app_colors.dart';
import 'package:gym_app/core/theme/responsive.dart';
import 'package:gym_app/features/exercises/models/muscle_group.dart';
import 'package:gym_app/features/exercises/screens/muscle_group_exercises_screen.dart';
import 'package:gym_app/features/exercises/screens/my_exercises_screen.dart';
import 'package:gym_app/features/exercises/services/exercise_service.dart';
import 'package:gym_app/shared/widgets/animated_tap.dart';
import 'package:gym_app/shared/widgets/cached_remote_image.dart';
import 'package:gym_app/shared/widgets/empty_state.dart';
import 'package:gym_app/shared/widgets/fade_slide_in.dart';
import 'package:gym_app/shared/widgets/skeleton_loader.dart';

/// Top of the exercise library: pick a muscle group, then browse its
/// exercises. Alongside the official (admin-curated) catalog, users can add
/// their own private exercises — either inline within a muscle group
/// (MuscleGroupExercisesScreen's FAB) or from the dedicated list reachable
/// via the header button here (MyExercisesScreen).
class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final ExerciseService _service = ExerciseService();
  late Future<List<MuscleGroup>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchMuscleGroups();
  }

  Future<void> _reload() async {
    setState(() => _future = _service.fetchMuscleGroups());
    await _future;
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
                  _BackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'home_exercises'.tr,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _MyExercisesButton(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyExercisesScreen()),
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
                child: FutureBuilder<List<MuscleGroup>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsetsDirectional.fromSTEB(
                            24.rs(context), 8.rs(context), 24.rs(context), 32.rs(context)),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.15,
                        ),
                        itemCount: 6,
                        itemBuilder: (context, index) => const SkeletonBox(borderRadius: 20),
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
                    final groups = snapshot.data ?? const [];
                    if (groups.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          AppEmptyState(
                            icon: Icons.fitness_center_rounded,
                            message: 'exercises_empty'.tr,
                          ),
                        ],
                      );
                    }
                    return GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsetsDirectional.fromSTEB(
                          24.rs(context), 8.rs(context), 24.rs(context), 32.rs(context)),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.15,
                      ),
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return FadeSlideIn(
                          delay: Duration(milliseconds: (60 * index).clamp(0, 400)),
                          child: _MuscleGroupCard(
                            group: group,
                            isArabic: isArabic,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MuscleGroupExercisesScreen(muscleGroup: group),
                              ),
                            ),
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

class _MuscleGroupCard extends StatelessWidget {
  const _MuscleGroupCard({
    required this.group,
    required this.isArabic,
    required this.onTap,
  });

  final MuscleGroup group;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return AnimatedTap(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: radius,
          border: Border.all(color: AppColors.darkBorderSubtle),
          boxShadow: AppColors.softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedRemoteImage(url: group.mediaUrl, iconSize: 36),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                  ),
                ),
                child: Text(
                  group.localizedName(isArabic),
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 15.rf(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyExercisesButton extends StatelessWidget {
  const _MyExercisesButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return AnimatedTap(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: radius,
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: const Icon(Icons.list_alt_rounded, color: AppColors.textGrey, size: 20),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return AnimatedTap(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: radius,
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: AppColors.textGrey, size: 19),
      ),
    );
  }
}
