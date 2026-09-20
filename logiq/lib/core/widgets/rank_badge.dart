import 'package:flutter/material.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';

class RankBadge extends StatelessWidget {
  final int rank;
  final bool isHighlighted;

  const RankBadge({
    super.key,
    required this.rank,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor = AppColors.white;

    switch (rank) {
      case 1:
        bgColor = AppColors.emerald; // L1 Leader in emerald green
        break;
      case 2:
        bgColor = AppColors.electricBlue; // L2 in electric blue
        break;
      case 3:
        bgColor = AppColors.amber; // L3 in amber
        break;
      default:
        bgColor = AppColors.surfaceAlt;
        fgColor = AppColors.navy;
    }

    if (isHighlighted) {
      // Can add scale or glow effect
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: isHighlighted ? Border.all(color: AppColors.ink, width: 2) : null,
        boxShadow: isHighlighted ? [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          )
        ] : [],
      ),
      child: Center(
        child: Text(
          'L$rank',
          style: AppTextStyles.bodyStrong.copyWith(color: fgColor),
        ),
      ),
    );
  }
}
