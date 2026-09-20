import 'package:flutter/material.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/core/utils/formatters.dart';

class TimerCard extends StatelessWidget {
  final int secondsRemaining;
  final int totalSeconds;
  final String stageLabel;

  const TimerCard({
    super.key,
    required this.secondsRemaining,
    required this.totalSeconds,
    this.stageLabel = 'LIVE AUCTION',
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = secondsRemaining < 30;
    final isWarning = secondsRemaining < 60 && !isUrgent;

    final bgColor = isUrgent
        ? AppColors.dangerSoft
        : isWarning
            ? AppColors.warningSoft
            : AppColors.surfaceAlt;

    final textColor = isUrgent
        ? AppColors.danger
        : isWarning
            ? AppColors.warning
            : AppColors.ink;

    final progress = totalSeconds > 0
        ? (secondsRemaining / totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent
              ? AppColors.danger.withValues(alpha: 0.3)
              : AppColors.outline,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: textColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    stageLabel,
                    style: AppTextStyles.labelBold.copyWith(color: textColor),
                  ),
                ],
              ),
              Text(
                Formatters.countdown(secondsRemaining),
                style: AppTextStyles.amount.copyWith(
                  color: textColor,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.outline,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
