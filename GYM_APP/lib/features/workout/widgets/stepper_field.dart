import 'package:flutter/material.dart';
import 'package:gym_app/core/theme/app_colors.dart';

/// Compact -/value/+ control used for reps and weight during logging.
/// Tapping the value itself opens a keyboard for a precise entry — the
/// buttons exist so the common case (repeat or small nudge) never needs
/// the keyboard at all.
class StepperField extends StatelessWidget {
  const StepperField({
    super.key,
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    required this.onTapValue,
  });

  final String label;
  final String value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onTapValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _roundButton(Icons.remove_rounded, onDecrement),
            GestureDetector(
              onTap: onTapValue,
              child: Container(
                constraints: const BoxConstraints(minWidth: 56),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            _roundButton(Icons.add_rounded, onIncrement),
          ],
        ),
      ],
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.textWhite, size: 16),
      ),
    );
  }
}
