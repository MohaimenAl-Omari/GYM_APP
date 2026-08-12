import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gym_app/core/theme/app_colors.dart';

/// Fixed banner shown while a rest timer is counting down. Big and simple
/// on purpose — the user glances at their phone between sets, not reads
/// fine print.
class RestTimerBanner extends StatelessWidget {
  const RestTimerBanner({
    super.key,
    required this.secondsRemaining,
    required this.totalSeconds,
    required this.onSkip,
  });

  final int secondsRemaining;
  final int totalSeconds;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    final progress = totalSeconds == 0 ? 0.0 : 1 - (secondsRemaining / totalSeconds);

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: AppColors.darkBorder)),
      ),
      child: Row(
        children: [
          Text(
            'resting'.tr,
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 6,
                backgroundColor: AppColors.darkCard,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onSkip,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'skip'.tr,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
