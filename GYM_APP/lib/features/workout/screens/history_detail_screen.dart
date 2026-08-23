import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gym_app/core/localization/locale_controller.dart';
import 'package:gym_app/core/theme/app_colors.dart';
import 'package:gym_app/core/theme/responsive.dart';
import 'package:gym_app/features/workout/models/logged_set.dart';
import 'package:gym_app/features/workout/models/workout_history.dart';
import 'package:gym_app/features/workout/screens/history_screen.dart' show formatDuration;
import 'package:gym_app/features/workout/services/workout_service.dart';
import 'package:gym_app/shared/widgets/animated_tap.dart';
import 'package:gym_app/shared/widgets/app_card.dart';
import 'package:gym_app/shared/widgets/app_notification.dart';
import 'package:gym_app/shared/widgets/fade_slide_in.dart';

/// Full exercise/set breakdown for one past session, opened from a
/// History list row. Also where a session can be renamed (notes) or
/// deleted — both act on the same session id the list already knows,
/// so on delete we just pop back with `true` and let History refresh.
class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  final WorkoutService _service = WorkoutService();
  late Future<WorkoutHistoryDetail> _future;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchSessionDetail(widget.sessionId);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_session'.tr),
        content: Text('delete_session_confirm'.tr),
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
    if (confirmed != true || _deleting) return;

    setState(() => _deleting = true);
    try {
      await _service.deleteSession(widget.sessionId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _deleting = false);
        AppNotification.showError(context, 'generic_error'.tr);
      }
    }
  }

  Future<void> _editNotes(String? currentNotes) async {
    final controller = TextEditingController(text: currentNotes ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('edit_notes'.tr),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: InputDecoration(
            hintText: 'notes_hint'.tr,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text('save'.tr),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;

    try {
      await _service.updateSessionNotes(widget.sessionId, result.trim().isEmpty ? null : result.trim());
      if (!mounted) return;
      setState(() {
        _future = _service.fetchSessionDetail(widget.sessionId);
      });
    } catch (_) {
      if (mounted) {
        AppNotification.showError(context, 'generic_error'.tr);
      }
    }
  }

  /// Fixes a typo'd historical set — e.g. logged 15kg instead of 51kg.
  /// Available on any set since editing doesn't disturb ordering.
  Future<void> _editSet(HistoryExercise exercise, HistorySet set) async {
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
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('cancel'.tr)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('save'.tr)),
        ],
      ),
    );
    if (saveTapped != true || !mounted) return;

    final reps = int.tryParse(repsController.text);
    final weight = double.tryParse(weightController.text);
    if (reps == null || weight == null) return;

    try {
      await _service.updateSet(
        widget.sessionId,
        set.id,
        LoggedSet(
          id: set.id,
          sessionExerciseId: exercise.sessionExerciseId,
          setNumber: set.setNumber,
          reps: reps,
          weight: weight,
          weightUnit: set.weightUnit,
          restTime: set.restTime,
        ),
      );
      if (!mounted) return;
      setState(() => _future = _service.fetchSessionDetail(widget.sessionId));
    } catch (_) {
      if (mounted) AppNotification.showError(context, 'generic_error'.tr);
    }
  }

  Future<void> _deleteSet(HistorySet set) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_set_title'.tr),
        content: Text('delete_set_confirm'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('delete'.tr, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _service.deleteSet(widget.sessionId, set.id);
      if (!mounted) return;
      setState(() => _future = _service.fetchSessionDetail(widget.sessionId));
    } catch (_) {
      if (mounted) AppNotification.showError(context, 'generic_error'.tr);
    }
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(24.rs(context), 12.rs(context), 24.rs(context), 0),
                    child: _BackButton(onTap: () => Navigator.of(context).pop()),
                  ),
                  const Expanded(
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ),
                ],
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(24.rs(context), 12.rs(context), 24.rs(context), 0),
                    child: _BackButton(onTap: () => Navigator.of(context).pop()),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'history_load_error'.tr,
                        style: TextStyle(color: AppColors.textGrey, fontSize: 14.rf(context)),
                      ),
                    ),
                  ),
                ],
              );
            }

            final detail = snapshot.data!;

            return SingleChildScrollView(
              padding: EdgeInsetsDirectional.fromSTEB(
                  24.rs(context), 12.rs(context), 24.rs(context), 32.rs(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _BackButton(onTap: () => Navigator.of(context).pop()),
                      const Spacer(),
                      AnimatedTap(
                        onTap: _deleting ? null : _confirmDelete,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.darkBorder),
                          ),
                          child: _deleting
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                                )
                              : const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 19),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.rs(context)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          detail.date,
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 22.rf(context),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (detail.durationSeconds != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined, color: AppColors.textGrey, size: 15),
                              const SizedBox(width: 4),
                              Text(
                                formatDuration(detail.durationSeconds!),
                                style: TextStyle(
                                    color: AppColors.textGrey, fontSize: 13.rf(context), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                    ],
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
                  SizedBox(height: 20.rs(context)),
                  FadeSlideIn(
                    child: Row(
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
                  ),
                  SizedBox(height: 20.rs(context)),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 60),
                    child: AppCard(
                      onTap: () => _editNotes(detail.notes),
                      color: AppColors.darkSurface,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              (detail.notes ?? '').isNotEmpty ? detail.notes! : 'no_notes'.tr,
                              style: TextStyle(
                                color: (detail.notes ?? '').isNotEmpty
                                    ? AppColors.textLightGrey
                                    : AppColors.textGrey,
                                fontSize: 13.rf(context),
                                height: 1.4,
                                fontStyle: (detail.notes ?? '').isNotEmpty
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.edit_outlined, color: AppColors.textGrey, size: 16),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24.rs(context)),
                  Text(
                    'history_exercises'.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...detail.exercises.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FadeSlideIn(
                        delay: Duration(milliseconds: (50 * entry.key).clamp(0, 400)),
                        child: _ExerciseCard(
                          exercise: entry.value,
                          isArabic: isArabic,
                          onEditSet: (set) => _editSet(entry.value, set),
                          onDeleteSet: _deleteSet,
                        ),
                      ),
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
    return AnimatedTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: AppColors.textGrey, size: 19),
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
    return AppCard(
      color: AppColors.darkSurface,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
                color: AppColors.textWhite, fontSize: 20.rf(context), fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
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
  const _ExerciseCard({
    required this.exercise,
    required this.isArabic,
    required this.onEditSet,
    required this.onDeleteSet,
  });

  final HistoryExercise exercise;
  final bool isArabic;
  final void Function(HistorySet set) onEditSet;
  final void Function(HistorySet set) onDeleteSet;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.darkSurface,
      padding: const EdgeInsets.all(16),
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
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 14.rf(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...exercise.sets.map(
            (set) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(
                      '${'set_label'.tr} ${set.setNumber}',
                      style: TextStyle(color: AppColors.textLightGrey, fontSize: 13.rf(context)),
                    ),
                  ),
                  Text(
                    '${set.reps} ${'reps_label'.tr}',
                    style: TextStyle(
                        color: AppColors.textWhite, fontSize: 13.rf(context), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${set.weight.toStringAsFixed(set.weight % 1 == 0 ? 0 : 1)} ${set.weightUnit}',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13.rf(context)),
                  ),
                  const Spacer(),
                  _HistorySetIconButton(
                    icon: Icons.edit_outlined,
                    color: AppColors.textGrey,
                    onTap: () => onEditSet(set),
                  ),
                  _HistorySetIconButton(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.error,
                    onTap: () => onDeleteSet(set),
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

/// 48x48dp tap target (see gym-app-mobile-ui-ux skill) around a small
/// inline icon — keeps the visual footprint compact for a dense set row
/// while the actual hit area still meets the minimum comfortable size.
class _HistorySetIconButton extends StatelessWidget {
  const _HistorySetIconButton({required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 16),
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      padding: EdgeInsets.zero,
      splashRadius: 22,
    );
  }
}
