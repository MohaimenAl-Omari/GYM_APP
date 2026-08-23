import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gym_app/core/localization/locale_controller.dart';
import 'package:gym_app/core/theme/app_colors.dart';
import 'package:gym_app/core/theme/responsive.dart';
import 'package:gym_app/features/exercises/models/exercise.dart';
import 'package:gym_app/features/exercises/models/exercise_last_performance.dart';
import 'package:gym_app/features/exercises/services/exercise_service.dart';
import 'package:gym_app/shared/widgets/animated_tap.dart';
import 'package:gym_app/shared/widgets/app_card.dart';
import 'package:gym_app/shared/widgets/fade_slide_in.dart';
import 'package:gym_app/shared/widgets/skeleton_loader.dart';

class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  final ExerciseService _service = ExerciseService();
  late Future<ExerciseLastPerformance> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchLastPerformance(widget.exercise.id);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Get.find<LocaleController>().isArabic;
    final exercise = widget.exercise;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsetsDirectional.fromSTEB(
              24.rs(context), 12.rs(context), 24.rs(context), 32.rs(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                ],
              ),
              SizedBox(height: 16.rs(context)),
              FadeSlideIn(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: exercise.demoUrl != null
                      ? Image.network(
                          exercise.demoUrl!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          // Image.network plays animated GIFs natively, so a
                          // gifUrl demo loops here just like a static photo
                          // would render.
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              SizedBox(height: 20.rs(context)),
              Text(
                exercise.localizedName(isArabic),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if ((exercise.localizedDescription(isArabic) ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  exercise.localizedDescription(isArabic)!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textGrey,
                        height: 1.5,
                      ),
                ),
              ],
              if (exercise.targetMuscle != null || exercise.secondaryMuscles.isNotEmpty) ...[
                SizedBox(height: 20.rs(context)),
                _MuscleChipsSection(exercise: exercise),
              ],
              if (exercise.instructions.isNotEmpty) ...[
                SizedBox(height: 24.rs(context)),
                Text(
                  'how_to'.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _InstructionsCard(instructions: exercise.instructions),
              ],
              SizedBox(height: 24.rs(context)),
              Text(
                'last_performance'.tr,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              FutureBuilder<ExerciseLastPerformance>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SkeletonCard(height: 84, margin: EdgeInsets.zero);
                  }
                  final performance = snapshot.data ?? ExerciseLastPerformance.empty;
                  if (!performance.hasHistory) {
                    return _EmptyHistoryCard();
                  }
                  return _LastPerformanceCard(performance: performance);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: 200,
      color: AppColors.darkSurface,
      child: const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 40),
    );
  }
}

class _LastPerformanceCard extends StatelessWidget {
  const _LastPerformanceCard({required this.performance});

  final ExerciseLastPerformance performance;

  @override
  Widget build(BuildContext context) {
    final date = performance.sessionDate;
    return AppCard(
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (date != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${'last_time_on'.tr} ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ...performance.sets.map(
            (set) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${'set_label'.tr} ${set.setNumber}',
                      style: TextStyle(color: AppColors.textLightGrey, fontSize: 13.rf(context)),
                    ),
                  ),
                  Text(
                    '${set.reps} ${'reps_label'.tr}',
                    style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 14.rf(context),
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '× ${set.weight.toStringAsFixed(set.weight % 1 == 0 ? 0 : 1)} ${set.weightUnit}',
                    style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 14.rf(context),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Primary target muscle highlighted in the app's accent color, secondary
/// muscles shown as muted chips — mirrors which muscles light up in a
/// muscle-highlight demo video, without needing one.
class _MuscleChipsSection extends StatelessWidget {
  const _MuscleChipsSection({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (exercise.targetMuscle != null)
          _MuscleChip(label: exercise.targetMuscle!, isPrimary: true),
        ...exercise.secondaryMuscles.map(
          (muscle) => _MuscleChip(label: muscle, isPrimary: false),
        ),
      ],
    );
  }
}

class _MuscleChip extends StatelessWidget {
  const _MuscleChip({required this.label, required this.isPrimary});

  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primary.withOpacity(0.16) : AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary ? AppColors.primary : AppColors.darkBorder,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isPrimary ? AppColors.primary : AppColors.textLightGrey,
          fontSize: 12.rf(context),
          fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  const _InstructionsCard({required this.instructions});

  final List<String> instructions;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < instructions.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == instructions.length - 1 ? 0 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.darkCardElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      instructions[i],
                      style: TextStyle(
                        color: AppColors.textLightGrey,
                        fontSize: 13.rf(context),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: 20,
      child: Text(
        'no_history_yet'.tr,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
