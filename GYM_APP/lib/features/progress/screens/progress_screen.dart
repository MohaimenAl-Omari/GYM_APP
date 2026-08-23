import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gym_app/core/localization/locale_controller.dart';
import 'package:gym_app/core/services/auth_service.dart';
import 'package:gym_app/core/theme/app_colors.dart';
import 'package:gym_app/core/theme/responsive.dart';
import 'package:gym_app/features/exercises/models/exercise.dart';
import 'package:gym_app/features/exercises/models/exercise_progress.dart';
import 'package:gym_app/features/exercises/models/muscle_group.dart';
import 'package:gym_app/features/exercises/services/exercise_service.dart';
import 'package:gym_app/features/progress/models/weight_log.dart';
import 'package:gym_app/features/progress/services/weight_log_service.dart';
import 'package:gym_app/features/workout/models/workout_history.dart';
import 'package:gym_app/features/workout/services/workout_service.dart';
import 'package:gym_app/shared/widgets/animated_tap.dart';
import 'package:gym_app/shared/widgets/app_card.dart';
import 'package:gym_app/shared/widgets/app_notification.dart';
import 'package:gym_app/shared/widgets/fade_slide_in.dart';

/// Progress tab — four sections built entirely from data the backend
/// already had (workout history, exercise sets) plus one small new
/// addition (weight_logs) for a real body-weight trend. Charts are plain
/// Container-based bars, not a charting package — this app has none, and
/// these totals don't need more than that.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final WorkoutService _workoutService = WorkoutService();
  final ExerciseService _exerciseService = ExerciseService();
  final WeightLogService _weightLogService = WeightLogService();
  final AuthService _authService = AuthService();

  late Future<List<WorkoutHistoryItem>> _historyFuture;
  late Future<List<MuscleGroup>> _muscleGroupsFuture;
  late Future<List<WeightLog>> _weightLogsFuture;
  late Future<Map<String, dynamic>> _userFuture;

  int? _selectedMuscleGroupId;
  List<Exercise> _exercisesForGroup = [];
  bool _loadingExercises = false;
  int? _selectedExerciseId;
  String _selectedExerciseName = '';
  Future<List<ExerciseProgressPoint>>? _exerciseProgressFuture;

  bool _loggingWeight = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() {
    _historyFuture = _workoutService.fetchHistory();
    _muscleGroupsFuture = _exerciseService.fetchMuscleGroups();
    _weightLogsFuture = _weightLogService.fetchLogs();
    _userFuture = _loadUser();
  }

  Future<Map<String, dynamic>> _loadUser() async {
    return _authService.fetchCurrentUser();
  }

  Future<void> _refresh() async {
    setState(_loadAll);
    await Future.wait([_historyFuture, _muscleGroupsFuture, _weightLogsFuture, _userFuture]);
  }

  Future<void> _selectMuscleGroup(int id) async {
    setState(() {
      _selectedMuscleGroupId = id;
      _selectedExerciseId = null;
      _exerciseProgressFuture = null;
      _loadingExercises = true;
    });
    try {
      final exercises = await _exerciseService.fetchExercisesForMuscleGroup(id);
      if (!mounted) return;
      setState(() {
        _exercisesForGroup = exercises;
        _loadingExercises = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingExercises = false);
    }
  }

  void _selectExercise(Exercise exercise, bool isArabic) {
    setState(() {
      _selectedExerciseId = exercise.id;
      _selectedExerciseName = exercise.localizedName(isArabic);
      _exerciseProgressFuture = _exerciseService.fetchExerciseProgress(exercise.id);
    });
  }

  Future<void> _logWeight(String currentUnit) async {
    final controller = TextEditingController();
    String unit = currentUnit;
    final result = await showDialog<double>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('log_weight'.tr),
          content: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.textWhite),
                  decoration: InputDecoration(
                    hintText: 'enter_weight'.tr,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: unit,
                dropdownColor: AppColors.darkCardElevated,
                style: const TextStyle(color: AppColors.textWhite),
                underline: Container(height: 1, color: AppColors.darkBorder),
                items: ['kg', 'lbs']
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) => setDialogState(() => unit = v ?? unit),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('cancel'.tr),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(double.tryParse(controller.text.trim())),
              child: Text('save'.tr),
            ),
          ],
        ),
      ),
    );
    if (result == null || result <= 0 || !mounted) return;

    setState(() => _loggingWeight = true);
    try {
      await _weightLogService.logWeight(weight: result, weightUnit: unit);
      if (!mounted) return;
      setState(() {
        _weightLogsFuture = _weightLogService.fetchLogs();
        _userFuture = _loadUser();
        _loggingWeight = false;
      });
      AppNotification.showSuccess(context, 'weight_logged'.tr);
    } catch (_) {
      if (mounted) {
        setState(() => _loggingWeight = false);
        AppNotification.showError(context, 'generic_error'.tr);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Get.find<LocaleController>().isArabic;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.darkSurface,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsetsDirectional.fromSTEB(
                24.rs(context), 12.rs(context), 24.rs(context), 32.rs(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedTap(
                      onTap: () => Navigator.of(context).pop(),
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
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'progress_title'.tr,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                SizedBox(height: 20.rs(context)),
                FutureBuilder<List<WorkoutHistoryItem>>(
                  future: _historyFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      );
                    }
                    final history = snapshot.data ?? const [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeSlideIn(child: _buildFrequencySection(history)),
                        SizedBox(height: 16.rs(context)),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 80),
                          child: _buildVolumeSection(history),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 16.rs(context)),
                FutureBuilder<List<MuscleGroup>>(
                  future: _muscleGroupsFuture,
                  builder: (context, snapshot) {
                    final groups = snapshot.data ?? const [];
                    if (groups.isEmpty) return const SizedBox.shrink();
                    return FadeSlideIn(
                      delay: const Duration(milliseconds: 160),
                      child: _buildStrengthSection(groups, isArabic),
                    );
                  },
                ),
                SizedBox(height: 16.rs(context)),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 240),
                  child: _buildBodyStatsSection(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencySection(List<WorkoutHistoryItem> history) {
    final weekStarts = List.generate(
      8,
      (i) => _startOfWeek(DateTime.now().subtract(Duration(days: (7 - i) * 7))),
    );
    final counts = List.filled(8, 0);
    for (final item in history) {
      final date = DateTime.tryParse(item.date);
      if (date == null) continue;
      final day = DateTime(date.year, date.month, date.day);
      for (var i = 0; i < weekStarts.length; i++) {
        final start = weekStarts[i];
        final end = start.add(const Duration(days: 7));
        if (!day.isBefore(start) && day.isBefore(end)) {
          counts[i]++;
          break;
        }
      }
    }
    final labels = weekStarts.map((d) => '${d.month}/${d.day}').toList();
    final streak = _computeStreak(history);

    return _SectionCard(
      title: 'progress_frequency'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MiniStat(
                icon: Icons.local_fire_department_rounded,
                value: '$streak',
                label: 'home_stat_streak'.tr,
              ),
              const SizedBox(width: 24),
              _MiniStat(
                icon: Icons.event_repeat_rounded,
                value: '${history.length}',
                label: 'progress_total_workouts'.tr,
              ),
            ],
          ),
          SizedBox(height: 18.rs(context)),
          history.isEmpty
              ? _EmptyHint(message: 'progress_no_data'.tr)
              : _TrendBars(values: counts.map((c) => c.toDouble()).toList(), labels: labels),
        ],
      ),
    );
  }

  Widget _buildVolumeSection(List<WorkoutHistoryItem> history) {
    // history is newest-first from the API — take the last 8 and reverse
    // so the chart reads left-to-right, oldest to newest.
    final recent = history.take(8).toList().reversed.toList();
    return _SectionCard(
      title: 'progress_volume'.tr,
      child: recent.isEmpty
          ? _EmptyHint(message: 'progress_no_data'.tr)
          : _TrendBars(
              values: recent.map((e) => e.totalVolume).toList(),
              labels: recent.map((e) => _shortDate(e.date)).toList(),
            ),
    );
  }

  Widget _buildStrengthSection(List<MuscleGroup> muscleGroups, bool isArabic) {
    return _SectionCard(
      title: 'progress_strength'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'progress_select_exercise'.tr,
            style: TextStyle(color: AppColors.textGrey, fontSize: 12.rf(context)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: muscleGroups.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final mg = muscleGroups[i];
                return _FilterChip(
                  label: mg.localizedName(isArabic),
                  selected: _selectedMuscleGroupId == mg.id,
                  onTap: () => _selectMuscleGroup(mg.id),
                );
              },
            ),
          ),
          if (_loadingExercises) ...[
            const SizedBox(height: 14),
            const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          ] else if (_exercisesForGroup.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _exercisesForGroup.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final ex = _exercisesForGroup[i];
                  return _FilterChip(
                    label: ex.localizedName(isArabic),
                    selected: _selectedExerciseId == ex.id,
                    onTap: () => _selectExercise(ex, isArabic),
                  );
                },
              ),
            ),
          ],
          if (_exerciseProgressFuture != null) ...[
            SizedBox(height: 18.rs(context)),
            FutureBuilder<List<ExerciseProgressPoint>>(
              future: _exerciseProgressFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                    ),
                  );
                }
                final points = (snapshot.data ?? const [])
                    .where((p) => p.sets.isNotEmpty)
                    .toList();
                if (points.isEmpty) {
                  return _EmptyHint(message: 'progress_no_data'.tr);
                }
                final recent = points.length > 8 ? points.sublist(points.length - 8) : points;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedExerciseName,
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 13.rf(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TrendBars(
                      values: recent.map((p) => p.topWeight).toList(),
                      labels: recent.map((p) => _shortDate(p.date)).toList(),
                      valueFormatter: (v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBodyStatsSection() {
    return _SectionCard(
      title: 'progress_body_stats'.tr,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _userFuture,
        builder: (context, userSnapshot) {
          final user = userSnapshot.data;
          final weight = (user?['weight'] as num?)?.toDouble();
          final height = (user?['height'] as num?)?.toDouble();
          final unit = user?['weight_unit']?.toString() ?? 'kg';
          final bmi = _computeBmi(weight, height, unit);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      icon: Icons.monitor_weight_outlined,
                      value: weight != null ? '${weight.toStringAsFixed(1)} $unit' : '–',
                      label: 'current_weight'.tr,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BmiStatTile(
                      value: bmi != null ? bmi.toStringAsFixed(1) : '–',
                      category: bmi != null ? _bmiCategory(bmi) : 'bmi_label'.tr,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.rs(context)),
              FutureBuilder<List<WeightLog>>(
                future: _weightLogsFuture,
                builder: (context, logSnapshot) {
                  if (logSnapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                      ),
                    );
                  }
                  final logs = logSnapshot.data ?? const [];
                  if (logs.isEmpty) {
                    return _EmptyHint(message: 'progress_no_data'.tr);
                  }
                  final recent = logs.length > 10 ? logs.sublist(logs.length - 10) : logs;
                  return _TrendBars(
                    values: recent.map((l) => l.weight).toList(),
                    labels: recent.map((l) => '${l.loggedAt.month}/${l.loggedAt.day}').toList(),
                    valueFormatter: (v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1),
                  );
                },
              ),
              SizedBox(height: 16.rs(context)),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loggingWeight ? null : () => _logWeight(unit),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _loggingWeight
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : const Icon(Icons.add_rounded, size: 18),
                  label: Text('log_weight'.tr),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Monday-anchored start of the calendar week containing [date] — same
/// convention as HomeScreen's stats row.
DateTime _startOfWeek(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

/// Consecutive-day streak, walking backward from today (or yesterday, if
/// nothing's logged yet today) — same logic as HomeScreen's streak stat,
/// duplicated here rather than shared since HomeScreen's version is a
/// private State method.
int _computeStreak(List<WorkoutHistoryItem> history) {
  final workoutDays = <DateTime>{};
  for (final item in history) {
    final parsed = DateTime.tryParse(item.date);
    if (parsed == null) continue;
    workoutDays.add(DateTime(parsed.year, parsed.month, parsed.day));
  }
  if (workoutDays.isEmpty) return 0;

  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  var cursor = workoutDays.contains(todayDate)
      ? todayDate
      : todayDate.subtract(const Duration(days: 1));

  var streak = 0;
  while (workoutDays.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

String _shortDate(String isoDate) {
  final date = DateTime.tryParse(isoDate);
  if (date == null) return isoDate;
  return '${date.month}/${date.day}';
}

/// Standard BMI formula (kg / m²) — converts from lbs first if that's the
/// user's unit. Null if either input is missing, so callers can show "–"
/// instead of a bogus number.
double? _computeBmi(double? weight, double? height, String unit) {
  if (weight == null || height == null || weight <= 0 || height <= 0) return null;
  final weightKg = unit == 'lbs' ? weight * 0.45359237 : weight;
  final heightM = height / 100;
  return weightKg / (heightM * heightM);
}

String _bmiCategory(double bmi) {
  if (bmi < 18.5) return 'bmi_underweight'.tr;
  if (bmi < 25) return 'bmi_normal'.tr;
  if (bmi < 30) return 'bmi_overweight'.tr;
  return 'bmi_obese'.tr;
}

/// Simple horizontal bar trend — deliberately not a charting package
/// (this app uses none); a fixed-height bar per point is enough for
/// "is this going up or down" at a glance.
class _TrendBars extends StatelessWidget {
  const _TrendBars({required this.values, required this.labels, this.valueFormatter});

  final List<double> values;
  final List<String> labels;
  final String Function(double)? valueFormatter;

  static const double _barAreaHeight = 90;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    final lastIndex = values.length - 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (i) {
        final barHeight = (_barAreaHeight * (values[i] / safeMax)).clamp(4.0, _barAreaHeight);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valueFormatter != null ? valueFormatter!(values[i]) : values[i].toStringAsFixed(0),
                  style: const TextStyle(
                      color: AppColors.textLightGrey, fontSize: 9, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _AnimatedBar(
                  height: barHeight,
                  color: i == lastIndex ? AppColors.chartBarActive : AppColors.chartBarInactive,
                  delay: Duration(milliseconds: (30 * i).clamp(0, 300)),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 9),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// Grows a single trend bar in from zero height, with an optional startup
/// [delay] so a row of bars can cascade in left-to-right. Re-animates
/// smoothly whenever [height] changes (e.g. switching exercises).
class _AnimatedBar extends StatefulWidget {
  const _AnimatedBar({required this.height, required this.color, this.delay = Duration.zero});

  final double height;
  final Color color;
  final Duration delay;

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar> {
  double _target = 0;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _target = widget.height;
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) setState(() => _target = widget.height);
      });
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.height != widget.height) {
      setState(() => _target = widget.height);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: _target),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Container(
        height: value,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.darkSurface,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 16.rs(context)),
          child,
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(color: AppColors.textWhite, fontSize: 15.rf(context), fontWeight: FontWeight.w800),
            ),
            Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message, style: TextStyle(color: AppColors.textGrey, fontSize: 12.rf(context))),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.darkBorder),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textGrey,
            fontSize: 12.rf(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Small stat tile for the BMI value + category, visually distinct from
/// the plain [_MiniStat] rows since it's the headline number in the Body
/// Stats section.
class _BmiStatTile extends StatelessWidget {
  const _BmiStatTile({required this.value, required this.category});

  final String value;
  final String category;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.darkCardElevated,
      borderColor: AppColors.darkBorderSubtle,
      borderRadius: 16,
      withShadow: false,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.straighten_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 15.rf(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(category, style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
        ],
      ),
    );
  }
}
