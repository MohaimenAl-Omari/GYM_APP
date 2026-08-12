import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gym_app/core/localization/locale_controller.dart';
import 'package:gym_app/core/theme/app_colors.dart';
import 'package:gym_app/features/exercises/models/exercise.dart';
import 'package:gym_app/features/exercises/models/exercise_last_performance.dart';
import 'package:gym_app/features/exercises/services/exercise_service.dart';
import 'package:gym_app/features/workout/models/logged_set.dart';
import 'package:gym_app/features/workout/models/session_exercise.dart';
import 'package:gym_app/features/workout/services/workout_service.dart';
import 'package:gym_app/features/workout/widgets/stepper_field.dart';

/// One exercise's logging surface inside the active workout session —
/// shown as a page in the parent PageView. Owns its own sets list and
/// "last time" reference; only tells the parent when a set is confirmed
/// (so the parent can kick off the rest timer).
class ExerciseLoggingPage extends StatefulWidget {
  const ExerciseLoggingPage({
    super.key,
    required this.sessionId,
    required this.sessionExercise,
    required this.exercise,
    required this.onSetLogged,
  });

  final int sessionId;
  final SessionExercise sessionExercise;
  final Exercise exercise;

  /// Called with (sessionExerciseId, totalConfirmedSets) right after a set
  /// is saved — the parent uses this both to start the rest timer and to
  /// keep its own progress map for the session overview panel in sync.
  final void Function(int sessionExerciseId, int totalConfirmedSets) onSetLogged;

  @override
  State<ExerciseLoggingPage> createState() => _ExerciseLoggingPageState();
}

class _ExerciseLoggingPageState extends State<ExerciseLoggingPage> {
  final ExerciseService _exerciseService = ExerciseService();
  final WorkoutService _workoutService = WorkoutService();

  late Future<ExerciseLastPerformance> _lastPerformanceFuture;
  final List<LoggedSet> _confirmedSets = [];

  int _draftReps = 10;
  double _draftWeight = 20;
  String _draftWeightUnit = 'kg';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _lastPerformanceFuture = _exerciseService.fetchLastPerformance(widget.exercise.id);
    _lastPerformanceFuture.then((performance) {
      if (!mounted || performance.sets.isEmpty) return;
      final first = performance.sets.first;
      setState(() {
        _draftReps = first.reps;
        _draftWeight = first.weight;
        _draftWeightUnit = first.weightUnit;
      });
    });
  }

  void _prefillNextDraft(ExerciseLastPerformance performance) {
    final nextSetNumber = _confirmedSets.length + 1;
    final matching = performance.sets.where((s) => s.setNumber == nextSetNumber);
    if (matching.isNotEmpty) {
      _draftReps = matching.first.reps;
      _draftWeight = matching.first.weight;
      _draftWeightUnit = matching.first.weightUnit;
    }
    // Otherwise keep whatever the user just confirmed — repeating the same
    // numbers is the most common case for an extra set.
  }

  Future<void> _confirmSet(ExerciseLastPerformance performance) async {
    if (_saving) return;
    setState(() => _saving = true);

    final set = LoggedSet(
      sessionExerciseId: widget.sessionExercise.id,
      setNumber: _confirmedSets.length + 1,
      reps: _draftReps,
      weight: _draftWeight,
      weightUnit: _draftWeightUnit,
      restTime: 90,
    );

    try {
      final saved = await _workoutService.logSet(widget.sessionId, set);
      if (!mounted) return;
      setState(() {
        _confirmedSets.add(saved);
        _prefillNextDraft(performance);
      });
      widget.onSetLogged(widget.sessionExercise.id, _confirmedSets.length);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('generic_error'.tr)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editValue({required bool isReps}) async {
    final controller = TextEditingController(
      text: isReps ? _draftReps.toString() : _draftWeight.toString(),
    );
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          isReps ? 'reps_label'.tr : 'weight'.tr,
          style: const TextStyle(color: AppColors.textWhite),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppColors.textWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text('save'.tr),
          ),
        ],
      ),
    );
    if (result == null) return;
    final parsed = double.tryParse(result);
    if (parsed == null) return;
    setState(() {
      if (isReps) {
        _draftReps = parsed.round();
      } else {
        _draftWeight = parsed;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Get.find<LocaleController>().isArabic;

    return FutureBuilder<ExerciseLastPerformance>(
      future: _lastPerformanceFuture,
      builder: (context, snapshot) {
        final performance = snapshot.data ?? ExerciseLastPerformance.empty;

        return SingleChildScrollView(
          // EdgeInsetsDirectional instead of EdgeInsets.fromLTRB: the old
          // values were symmetric (24/24) so this doesn't change how it
          // looks today, but it means padding stays correct if this ever
          // becomes asymmetric — see gym-app-mobile-ui-ux skill.
          padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: widget.exercise.demoUrl != null
                    ? Image.network(
                        widget.exercise.demoUrl!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
              const SizedBox(height: 16),
              Text(
                widget.exercise.localizedName(isArabic),
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (performance.hasHistory) ...[
                const SizedBox(height: 8),
                Text(
                  '${'last_time'.tr}: ${performance.sets.map((s) => '${s.reps}×${s.weight.toStringAsFixed(s.weight % 1 == 0 ? 0 : 1)}${s.weightUnit}').join(', ')}',
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                ),
              ],
              const SizedBox(height: 20),
              ..._confirmedSets.map((set) => _ConfirmedSetRow(set: set)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  children: [
                    Text(
                      '${'set_label'.tr} ${_confirmedSets.length + 1}',
                      style: const TextStyle(
                        color: AppColors.textLightGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        StepperField(
                          label: 'reps_label'.tr,
                          value: '$_draftReps',
                          onDecrement: () => setState(() {
                            if (_draftReps > 1) _draftReps -= 1;
                          }),
                          onIncrement: () => setState(() => _draftReps += 1),
                          onTapValue: () => _editValue(isReps: true),
                        ),
                        StepperField(
                          label: '${'weight'.tr} ($_draftWeightUnit)',
                          value: _draftWeight.toStringAsFixed(_draftWeight % 1 == 0 ? 0 : 1),
                          onDecrement: () => setState(() {
                            if (_draftWeight >= 2.5) _draftWeight -= 2.5;
                          }),
                          onIncrement: () => setState(() => _draftWeight += 2.5),
                          onTapValue: () => _editValue(isReps: false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : () => _confirmSet(performance),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: _saving
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                        label: Text(
                          'confirm_set'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 180,
      color: AppColors.darkSurface,
      child: const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 40),
    );
  }
}

class _ConfirmedSetRow extends StatelessWidget {
  const _ConfirmedSetRow({required this.set});

  final LoggedSet set;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
          const SizedBox(width: 10),
          Text(
            '${'set_label'.tr} ${set.setNumber}',
            style: const TextStyle(color: AppColors.textLightGrey, fontSize: 13),
          ),
          const Spacer(),
          Text(
            '${set.reps} ${'reps_label'.tr}  ×  ${set.weight.toStringAsFixed(set.weight % 1 == 0 ? 0 : 1)} ${set.weightUnit}',
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
