import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class RankBadge extends StatelessWidget {
  final String rank;
  final double size;

  const RankBadge({
    super.key,
    required this.rank,
    this.size = 48,
  });

  Color get _color {
    return switch (rank) {
      'L1' => AppColors.rankL1,
      'L2' => AppColors.rankL2,
      'L3' => AppColors.rankL3,
      _ => AppColors.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color.withAlpha(51),
        border: Border.all(
          color: _color,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          rank,
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
            color: _color,
          ),
        ),
      ),
    );
  }
}