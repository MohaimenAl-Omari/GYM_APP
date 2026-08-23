import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gym_app/core/theme/app_colors.dart';
import 'package:gym_app/features/home/screens/home_screen.dart';
import 'package:gym_app/features/workout/models/workout_session.dart';
import 'package:gym_app/shared/widgets/fade_slide_in.dart';
import 'package:gym_app/core/theme/responsive.dart';

class WorkoutSummaryScreen extends StatefulWidget {
  const WorkoutSummaryScreen({super.key, required this.summary});

  final WorkoutSummary summary;

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _checkController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _checkScale = CurvedAnimation(
    parent: _checkController,
    curve: Curves.elasticOut,
  );

  @override
  void initState() {
    super.initState();
    _checkController.forward();
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final minutes = summary.durationSeconds ~/ 60;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
              24.rs(context), 40.rs(context), 24.rs(context), 32.rs(context)),
          child: Column(
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _checkScale,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: AppColors.primaryGlow,
                  ),
                  child: const Icon(Icons.check_rounded, color: AppColors.textWhite, size: 46),
                ),
              ),
              SizedBox(height: 24.rs(context)),
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: Text(
                  'workout_complete'.tr,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: const Duration(milliseconds: 180),
                child: Text(
                  'workout_complete_subtitle'.tr,
                  style: TextStyle(color: AppColors.textGrey, fontSize: 14.rf(context)),
                ),
              ),
              SizedBox(height: 32.rs(context)),
              Row(
                children: [
                  Expanded(
                    child: FadeSlideIn(
                      delay: const Duration(milliseconds: 240),
                      child: _StatTile(value: '$minutes', label: 'home_stat_minutes'.tr),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FadeSlideIn(
                      delay: const Duration(milliseconds: 300),
                      child: _StatTile(value: '${summary.totalSets}', label: 'total_sets'.tr),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FadeSlideIn(
                      delay: const Duration(milliseconds: 360),
                      child: _StatTile(
                        value: summary.totalVolume.toStringAsFixed(0),
                        label: 'total_volume'.tr,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              FadeSlideIn(
                delay: const Duration(milliseconds: 420),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'done'.tr,
                      style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 15.rf(context),
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 20.rf(context),
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
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
