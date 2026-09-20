import 'package:flutter/material.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';

class LocationCard extends StatelessWidget {
  final String pickup;
  final String drop;
  final String? subtitle;

  const LocationCard({
    super.key,
    required this.pickup,
    required this.drop,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.radio_button_checked,
                color: AppColors.success,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pickup,
                  style: AppTextStyles.bodyStrong.copyWith(fontSize: 16),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Container(
              height: 20,
              width: 2,
              color: AppColors.outline,
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: AppColors.danger,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  drop,
                  style: AppTextStyles.bodyStrong.copyWith(fontSize: 16),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.outline, height: 1),
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: AppTextStyles.caption.copyWith(color: AppColors.inkSoft),
            ),
          ],
        ],
      ),
    );
  }
}
