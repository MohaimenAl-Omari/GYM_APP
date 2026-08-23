import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gym_app/core/localization/locale_controller.dart';
import 'package:gym_app/core/theme/app_colors.dart';
import 'package:gym_app/core/theme/responsive.dart';
import 'package:gym_app/features/workout/models/workout_history.dart';
import 'package:gym_app/features/workout/screens/history_detail_screen.dart';
import 'package:gym_app/features/workout/services/workout_service.dart';
import 'package:gym_app/shared/widgets/animated_tap.dart';
import 'package:gym_app/shared/widgets/app_card.dart';
import 'package:gym_app/shared/widgets/empty_state.dart';
import 'package:gym_app/shared/widgets/fade_slide_in.dart';

/// The History tab — every workout session the user has ever started,
/// most recent first, filterable by muscle group and date range. Tapping
/// a row opens HistoryDetailScreen for the full exercise/set breakdown.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final WorkoutService _service = WorkoutService();
  late Future<List<WorkoutHistoryItem>> _future;

  // Empty set = no muscle-group filter applied (shows everything).
  final Set<int> _selectedMuscleGroupIds = {};
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchHistory();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.fetchHistory();
    });
    await _future;
  }

  List<WorkoutHistoryItem> _applyFilters(List<WorkoutHistoryItem> sessions) {
    return sessions.where((item) {
      if (_selectedMuscleGroupIds.isNotEmpty &&
          !item.muscleGroups.any((mg) => _selectedMuscleGroupIds.contains(mg.id))) {
        return false;
      }
      if (_dateRange != null) {
        final date = DateTime.tryParse(item.date);
        if (date == null) return false;
        final day = DateTime(date.year, date.month, date.day);
        final start = DateTime(_dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
        final end = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day);
        if (day.isBefore(start) || day.isAfter(end)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _dateRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.darkSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  bool get _hasActiveFilters => _selectedMuscleGroupIds.isNotEmpty || _dateRange != null;

  void _clearFilters() {
    setState(() {
      _selectedMuscleGroupIds.clear();
      _dateRange = null;
    });
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
                  24.rs(context), 12.rs(context), 24.rs(context), 12.rs(context)),
              child: Row(
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
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textGrey, size: 19),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'history_title'.tr,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  AnimatedTap(
                    onTap: _pickDateRange,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _dateRange != null ? AppColors.primary.withOpacity(0.15) : AppColors.darkCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _dateRange != null ? AppColors.primary : AppColors.darkBorder,
                        ),
                      ),
                      child: Icon(
                        Icons.date_range_rounded,
                        color: _dateRange != null ? AppColors.primary : AppColors.textGrey,
                        size: 19,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.darkSurface,
                onRefresh: _refresh,
                child: FutureBuilder<List<WorkoutHistoryItem>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      );
                    }

                    if (snapshot.hasError) {
                      return AppEmptyState(
                        icon: Icons.error_outline_rounded,
                        message: 'history_load_error'.tr,
                      );
                    }

                    final allSessions = snapshot.data ?? const [];

                    if (allSessions.isEmpty) {
                      return AppEmptyState(
                        icon: Icons.history_rounded,
                        message: 'history_empty'.tr,
                      );
                    }

                    // Every muscle group that appears in at least one
                    // session — the filter row only ever offers choices
                    // that could actually narrow the list down.
                    final availableGroups = <int, String>{};
                    for (final item in allSessions) {
                      for (final mg in item.muscleGroups) {
                        availableGroups[mg.id] = mg.localizedName(isArabic);
                      }
                    }

                    final sessions = _applyFilters(allSessions);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (availableGroups.length > 1 || _hasActiveFilters)
                          SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsetsDirectional.fromSTEB(24.rs(context), 0, 24.rs(context), 0),
                              children: [
                                _FilterChip(
                                  label: 'history_filter_all'.tr,
                                  selected: !_hasActiveFilters,
                                  onTap: _clearFilters,
                                ),
                                const SizedBox(width: 8),
                                ...availableGroups.entries.map(
                                  (entry) => Padding(
                                    padding: const EdgeInsetsDirectional.only(end: 8),
                                    child: _FilterChip(
                                      label: entry.value,
                                      selected: _selectedMuscleGroupIds.contains(entry.key),
                                      onTap: () => setState(() {
                                        if (_selectedMuscleGroupIds.contains(entry.key)) {
                                          _selectedMuscleGroupIds.remove(entry.key);
                                        } else {
                                          _selectedMuscleGroupIds.add(entry.key);
                                        }
                                      }),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: sessions.isEmpty
                              ? AppEmptyState(
                                  icon: Icons.filter_alt_off_rounded,
                                  message: 'history_no_results'.tr,
                                )
                              : ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      24.rs(context), 0, 24.rs(context), 32.rs(context)),
                                  itemCount: sessions.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) => FadeSlideIn(
                                    delay: Duration(milliseconds: (50 * index).clamp(0, 400)),
                                    child: _HistoryCard(
                                      item: sessions[index],
                                      isArabic: isArabic,
                                      onTap: () async {
                                        final deleted = await Navigator.of(context).push<bool>(
                                          MaterialPageRoute(
                                            builder: (_) => HistoryDetailScreen(sessionId: sessions[index].id),
                                          ),
                                        );
                                        if (deleted == true) _refresh();
                                      },
                                    ),
                                  ),
                                ),
                        ),
                      ],
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

/// Formats a duration in seconds as e.g. "42 min" or "1h 12m" — matches
/// the compact style already used for stat values elsewhere in the app.
String formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '${minutes}m';
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  return remainder == 0 ? '${hours}h' : '${hours}h ${remainder}m';
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

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.item,
    required this.isArabic,
    required this.onTap,
  });

  final WorkoutHistoryItem item;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: AppColors.darkSurface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.date,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (item.durationSeconds != null) ...[
                const Icon(Icons.timer_outlined, color: AppColors.textGrey, size: 14),
                const SizedBox(width: 4),
                Text(
                  formatDuration(item.durationSeconds!),
                  style: TextStyle(color: AppColors.textGrey, fontSize: 12.rf(context), fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 10),
              ],
              const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey, size: 20),
            ],
          ),
          if (item.muscleGroups.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: item.muscleGroups
                  .map((mg) => _Chip(label: mg.localizedName(isArabic)))
                  .toList(),
            ),
          ],
          SizedBox(height: 16.rs(context)),
          Row(
            children: [
              _StatItem(
                icon: Icons.fitness_center_rounded,
                value: '${item.exerciseCount}',
                label: 'history_exercises'.tr,
              ),
              const SizedBox(width: 20),
              _StatItem(
                icon: Icons.repeat_rounded,
                value: '${item.totalSets}',
                label: 'total_sets'.tr,
              ),
              const SizedBox(width: 20),
              _StatItem(
                icon: Icons.show_chart_rounded,
                value: item.totalVolume.toStringAsFixed(0),
                label: 'total_volume'.tr,
              ),
            ],
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

class _StatItem extends StatelessWidget {
  const _StatItem({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textGrey, size: 15),
        const SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(color: AppColors.textWhite, fontSize: 13.rf(context), fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
        ),
      ],
    );
  }
}
