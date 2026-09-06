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
import 'package:gym_app/shared/widgets/app_notification.dart';
import 'package:gym_app/shared/widgets/cached_remote_image.dart';
import 'package:gym_app/shared/widgets/fade_slide_in.dart';
import 'package:gym_app/core/theme/responsive.dart';

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
    this.initialSets = const [],
  });

  final int sessionId;
  final SessionExercise sessionExercise;
  final Exercise exercise;

  /// Sets already confirmed for this exercise before the page was built —
  /// non-empty only when resuming an unfinished session (see
  /// ResumeWorkout). Lets a resumed session continue from the right set
  /// number instead of restarting at 1 and colliding with sets already
  /// saved server-side.
  final List<LoggedSet> initialSets;

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
    if (widget.initialSets.isNotEmpty) {
      _confirmedSets.addAll(widget.initialSets);
      // Seed the next set's draft from the last one already logged, same
      // as what normally happens right after confirming a set — otherwise
      // a resumed session would default back to 10 reps / 20kg instead of
      // continuing from where the user left off.
      final last = widget.initialSets.last;
      _draftReps = last.reps;
      _draftWeight = last.weight;
      _draftWeightUnit = last.weightUnit;
    }
    _lastPerformanceFuture = _exerciseService.fetchLastPerformance(widget.exercise.id);
    _lastPerformanceFuture.then((performance) {
      if (!mounted || performance.sets.isEmpty) return;
      if (_confirmedSets.isNotEmpty) {
        // Already resumed with real sets from this session — prefer
        // continuing that progression over overwriting it with an
        // unrelated past session's first-set numbers.
        setState(() => _prefillNextDraft(performance));
        return;
      }
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
    } catch (e) {
      // Logged so the real cause shows in the device console instead of
      // only ever surfacing as an unhelpful generic banner.
      debugPrint('ConfirmSet failed: $e');
      if (mounted) {
        AppNotification.showError(context, 'generic_error'.tr);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Fixes a typo'd set without deleting and re-confirming it. Available
  /// on any confirmed set (editing doesn't disturb ordering).
  Future<void> _editConfirmedSet(int index) async {
    final set = _confirmedSets[index];
    if (set.id == null) return;
    final repsController = TextEditingController(text: set.reps.toString());
    final weightController = TextEditingController(text: set.weight.toString());

    final saveTapped = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('edit_set_title'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: repsController,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textWhite),
              decoration: InputDecoration(labelText: 'reps_label'.tr),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textWhite),
              decoration: InputDecoration(labelText: '${'weight'.tr} (${set.weightUnit})'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('save'.tr),
          ),
        ],
      ),
    );
    if (saveTapped != true || !mounted) return;

    final reps = int.tryParse(repsController.text);
    final weight = double.tryParse(weightController.text);
    if (reps == null || weight == null) return;

    final updated = LoggedSet(
      id: set.id,
      sessionExerciseId: set.sessionExerciseId,
      setNumber: set.setNumber,
      reps: reps,
      weight: weight,
      weightUnit: set.weightUnit,
      restTime: set.restTime,
    );
    try {
      await _workoutService.updateSet(widget.sessionId, set.id!, updated);
      if (!mounted) return;
      setState(() => _confirmedSets[index] = updated);
    } catch (e) {
      debugPrint('UpdateSet failed: $e');
      if (mounted) AppNotification.showError(context, 'generic_error'.tr);
    }
  }

  /// Only the most recently confirmed set can be deleted — removing one
  /// from the middle would leave a gap in `set_number` that could collide
  /// with the next new set's number (the backend doesn't renumber the
  /// rest on delete). "Undo my last mistake" is the real-world case this
  /// covers anyway.
  Future<void> _deleteLastConfirmedSet() async {
    if (_confirmedSets.isEmpty) return;
    final index = _confirmedSets.length - 1;
    final set = _confirmedSets[index];
    if (set.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_set_title'.tr),
        content: Text('delete_set_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('delete'.tr, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _workoutService.deleteSet(widget.sessionId, set.id!);
      if (!mounted) return;
      setState(() => _confirmedSets.removeAt(index));
      widget.onSetLogged(widget.sessionExercise.id, _confirmedSets.length);
    } catch (e) {
      debugPrint('DeleteSet failed: $e');
      if (mounted) AppNotification.showError(context, 'generic_error'.tr);
    }
  }

  Future<void> _editValue({required bool isReps}) async {
    final controller = TextEditingController(
      text: isReps ? _draftReps.toString() : _draftWeight.toString(),
    );
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isReps ? 'reps_label'.tr : 'weight'.tr),
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

  /// Shows the exercise's demo image/GIF full-size in a dialog over the
  /// current page — deliberately not a route push, so the user is still
  /// exactly where they were in the workout when they dismiss it (tap
  /// outside, or the close button).
  void _showFullDemo(BuildContext context) {
    final url = widget.exercise.demoUrl;
    if (url == null) return;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          alignment: AlignmentDirectional.topEnd,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedRemoteImage(
                url: url,
                width: double.infinity,
                fit: BoxFit.contain,
                iconSize: 48,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: _RowIconButton(
                icon: Icons.close_rounded,
                color: AppColors.textWhite,
                onTap: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ],
        ),
      ),
    );
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
          padding: EdgeInsetsDirectional.fromSTEB(
              24.rs(context), 8.rs(context), 24.rs(context), 24.rs(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                // Full demo is already shown inline right here, but it's
                // small — tapping opens it large without leaving the
                // workout (a dialog over this same page, not a route
                // push), for anyone who wants a closer look at the
                // movement mid-set.
                onTap: widget.exercise.demoUrl == null
                    ? null
                    : () => _showFullDemo(context),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedRemoteImage(
                        url: widget.exercise.demoUrl,
                        width: double.infinity,
                        height: 180,
                        iconSize: 40,
                      ),
                    ),
                    if (widget.exercise.demoUrl != null)
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.fullscreen_rounded,
                            color: AppColors.textWhite,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 16.rs(context)),
              Text(
                widget.exercise.localizedName(isArabic),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (performance.hasHistory) ...[
                const SizedBox(height: 8),
                Text(
                  '${'last_time'.tr}: ${performance.sets.map((s) => '${s.reps}×${s.weight.toStringAsFixed(s.weight % 1 == 0 ? 0 : 1)}${s.weightUnit}').join(', ')}',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 12.rf(context)),
                ),
              ],
              SizedBox(height: 20.rs(context)),
              ..._confirmedSets.asMap().entries.map(
                    (entry) => FadeSlideIn(
                      delay: Duration(milliseconds: 60 * entry.key),
                      child: _ConfirmedSetRow(
                        set: entry.value,
                        onEdit: () => _editConfirmedSet(entry.key),
                        // Only the last row gets a delete affordance — see
                        // _deleteLastConfirmedSet for why.
                        onDelete: entry.key == _confirmedSets.length - 1
                            ? _deleteLastConfirmedSet
                            : null,
                      ),
                    ),
                  ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.darkBorder),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  children: [
                    Text(
                      '${'set_label'.tr} ${_confirmedSets.length + 1}',
                      style: TextStyle(
                        color: AppColors.textLightGrey,
                        fontSize: 12.rf(context),
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
                    SizedBox(height: 16.rs(context)),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : () => _confirmSet(performance),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: _saving
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.textWhite),
                              )
                            : const Icon(Icons.check_rounded, color: AppColors.textWhite, size: 18),
                        label: Text(
                          'confirm_set'.tr,
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 14.rf(context),
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
}

class _ConfirmedSetRow extends StatelessWidget {
  const _ConfirmedSetRow({required this.set, required this.onEdit, this.onDelete});

  final LoggedSet set;
  final VoidCallback onEdit;

  /// Null hides the delete button entirely — only the most recently
  /// confirmed set is deletable (see _deleteLastConfirmedSet).
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 4, 4),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
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
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 4),
          _RowIconButton(icon: Icons.edit_outlined, color: AppColors.textGrey, onTap: onEdit),
          if (onDelete != null)
            _RowIconButton(icon: Icons.delete_outline_rounded, color: AppColors.error, onTap: onDelete!),
        ],
      ),
    );
  }
}

/// 48x48dp tap target (see gym-app-mobile-ui-ux skill) around a small
/// inline icon — the visual footprint stays compact enough for a set row
/// while the actual hit area still meets the minimum comfortable size for
/// a screen used one-handed, often mid-workout.
class _RowIconButton extends StatelessWidget {
  const _RowIconButton({required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 16),
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      splashRadius: 22,
    );
  }
}
