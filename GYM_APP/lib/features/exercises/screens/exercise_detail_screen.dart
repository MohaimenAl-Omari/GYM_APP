import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gym_app/core/localization/locale_controller.dart';
import 'package:gym_app/core/theme/app_colors.dart';
import 'package:gym_app/features/exercises/models/exercise.dart';
import 'package:gym_app/features/exercises/models/exercise_last_performance.dart';
import 'package:gym_app/features/exercises/services/exercise_service.dart';

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
          padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textGrey, size: 19),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
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
              const SizedBox(height: 20),
              Text(
                exercise.localizedName(isArabic),
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if ((exercise.localizedDescription(isArabic) ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  exercise.localizedDescription(isArabic)!,
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 14, height: 1.5),
                ),
              ],
              if (exercise.targetMuscle != null || exercise.secondaryMuscles.isNotEmpty) ...[
                const SizedBox(height: 20),
                _MuscleChipsSection(exercise: exercise),
              ],
              if (exercise.instructions.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'how_to'.tr,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _InstructionsCard(instructions: exercise.instructions),
              ],
              const SizedBox(height: 24),
              Text(
                'last_performance'.tr,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<ExerciseLastPerformance>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    );
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (date != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '${'last_time_on'.tr} ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
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
                      style: const TextStyle(color: AppColors.textLightGrey, fontSize: 13),
                    ),
                  ),
                  Text(
                    '${set.reps} ${'reps_label'.tr}',
                    style: const TextStyle(
                        color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '× ${set.weight.toStringAsFixed(set.weight % 1 == 0 ? 0 : 1)} ${set.weightUnit}',
                    style: const TextStyle(
                        color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w600),
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
          fontSize: 12,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
      ),
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
                      color: AppColors.darkCard,
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      instructions[i],
                      style: const TextStyle(
                        color: AppColors.textLightGrey,
                        fontSize: 13,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Text(
        'no_history_yet'.tr,
        style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
      ),
    );
  }
}
