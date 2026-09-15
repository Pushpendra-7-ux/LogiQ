import 'package:flutter/material.dart';

import '../../models/tender.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

class TenderCard extends StatelessWidget {
  final Tender tender;
  final VoidCallback? onTap;

  const TenderCard({
    super.key,
    required this.tender,
    this.onTap,
  });

  Color get _statusColor {
    if (tender.status.contains('LIVE')) return AppColors.liveGreen;
    if (tender.status == 'COMPLETED' || tender.status == 'WINNER_FINALIZED') {
      return AppColors.accent;
    }
    if (tender.status == 'DRAFT') return AppColors.textSecondary;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_shipping, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tender.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tender.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      Formatters.route(
                        tender.pickupLocation,
                        tender.dropLocation,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    Formatters.dateRange(
                      tender.deliveryStart,
                      tender.deliveryEnd,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (tender.materials.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.inventory_2,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${tender.materials.first.quantity} '
                        '${tender.materials.first.unit} '
                        '${tender.materials.first.description}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}