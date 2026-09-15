import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StageIndicator extends StatelessWidget {
  final int stage;
  const StageIndicator({super.key, required this.stage});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: stage == 1 ? AppColors.primary : AppColors.blindPurple,
      borderRadius: BorderRadius.circular(20)),
    child: Text(stage == 1 ? 'STAGE 1' : 'FINAL AUCTION',
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
  );
}