import 'package:flutter/material.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/models/material.dart';

class MaterialCard extends StatelessWidget {
  final MaterialItem material;
  final VoidCallback? onDelete;

  const MaterialCard({
    super.key,
    required this.material,
    this.onDelete,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.electricBlueLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.electricBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.description,
                      style: AppTextStyles.bodyStrong.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'HSN: ${material.hsnCode}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.danger),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${material.quantity} ${material.unit}',
                  style: AppTextStyles.bodyStrong.copyWith(fontSize: 14),
                ),
              ),
              if (material.remarks.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    material.remarks,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.inkSoft,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
