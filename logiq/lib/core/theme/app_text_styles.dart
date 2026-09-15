import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle timer = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    fontFamily: 'monospace',
  );

  static const TextStyle timerSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontFamily: 'monospace',
  );

  static const TextStyle rank = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle bidAmount = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const TextStyle currency = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle error = TextStyle(
    fontSize: 14,
    color: AppColors.error,
  );
}