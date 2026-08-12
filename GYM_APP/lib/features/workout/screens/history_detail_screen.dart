import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gym_app/core/localization/locale_controller.dart';
import 'package:gym_app/core/theme/app_colors.dart';
import 'package:gym_app/features/workout/models/workout_history.dart';
import 'package:gym_app/features/workout/services/workout_service.dart';

/// Full exercise/set breakdown for one past session, opened from a
/// History list row.
class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  final WorkoutService _service = WorkoutService();
  late Future<WorkoutHistoryDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchSessionDetail(widget.sessionId);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Get.find<LocaleController>().isArabic;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: FutureBuilder<WorkoutHistoryDetail>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackButton(onTap: () => Navigator.of(context).pop()),
                  Expanded(
                    child: Center(
                      child: Text(
                        'history_load_error'.tr,
                        style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              );
            }

            final detail = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(height: 16),
                  Text(
                    detail.date,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (detail.muscleGroups.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: detail.muscleGroups
                          .map((mg) => _Chip(label: mg.localizedName(isArabic)))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          value: '${detail.exercises.length}',
                          label: 'history_exercises'.tr,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(value: '${detail.totalSets}', label: 'total_sets'.tr),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          value: detail.totalVolume.toStringAsFixed(0),
                          label: 'total_volume'.tr,
                        ),
                      ),
                    ],
                  ),
                  if ((detail.notes ?? '').isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: Text(
                        detail.notes!,
                        style: const TextStyle(color: AppColors.textLightGrey, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'history_exercises'.tr,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...detail.exercises.map(
                    (exercise) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ExerciseCard(exercise: exercise, isArabic: isArabic),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: AppColors.textGrey, size: 19),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
                color: AppColors.textWhite, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, required this.isArabic});

  final HistoryExercise exercise;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: exercise.demoUrl != null
                    ? Image.network(
                        exercise.demoUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _thumbnailPlaceholder(),
                      )
                    : _thumbnailPlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  exercise.localizedName(isArabic),
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...exercise.sets.map(
            (set) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(
                      '${'set_label'.tr} ${set.setNumber}',
                      style: const TextStyle(color: AppColors.textLightGrey, fontSize: 13),
                    ),
                  ),
                  Text(
                    '${set.reps} ${'reps_label'.tr}',
                    style: const TextStyle(
                        color: AppColors.textWhite, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${set.weight.toStringAsFixed(set.weight % 1 == 0 ? 0 : 1)} ${set.weightUnit}',
                    style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbnailPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      color: AppColors.darkCard,
      child: const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 20),
    );
  }
}
