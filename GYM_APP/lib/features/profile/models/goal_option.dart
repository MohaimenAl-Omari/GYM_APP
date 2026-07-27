import 'package:flutter/material.dart';

/// A selectable fitness goal shown on the "complete your profile" screen.
///
/// [value] is what gets sent to the backend (matches the `goal` column),
/// [labelKey] is the translation key shown to the user.
class GoalOption {
  const GoalOption({
    required this.value,
    required this.labelKey,
    required this.icon,
  });

  final String value;
  final String labelKey;
  final IconData icon;

  static const List<GoalOption> all = [
    GoalOption(
      value: 'lose_weight',
      labelKey: 'goal_lose_weight',
      icon: Icons.trending_down_rounded,
    ),
    GoalOption(
      value: 'build_muscle',
      labelKey: 'goal_build_muscle',
      icon: Icons.fitness_center_rounded,
    ),
    GoalOption(
      value: 'improve_fitness',
      labelKey: 'goal_improve_fitness',
      icon: Icons.directions_run_rounded,
    ),
    GoalOption(
      value: 'maintain_weight',
      labelKey: 'goal_maintain_weight',
      icon: Icons.balance_rounded,
    ),
  ];
}
