import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/core/widgets/route_display.dart';
import 'package:logiq/core/widgets/status_chip.dart';
import 'package:logiq/models/tender.dart';

class TenderCard extends StatelessWidget {
  final Tender tender;
  final VoidCallback onTap;
  final int bidCount;
  final int animationIndex;

  const TenderCard({
    super.key,
    required this.tender,
    required this.onTap,
    this.bidCount = 0,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Handling dynamic/optional fields based on general tender structure
    final String title = (tender as dynamic).title ?? 'Transport Material';
    final String status = (tender as dynamic).status?.toString() ?? 'Active';
    final String pickup = (tender as dynamic).pickup ?? 'Origin';
    final String dropoff = (tender as dynamic).dropoff ?? 'Destination';
    final String material = (tender as dynamic).material ?? 'General Goods';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.h3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                StatusChip(
                  label: status,
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 16),
            RouteDisplay(
              pickup: pickup,
              drop: dropoff,
              compact: true,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    material,
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
                if (bidCount > 0)
                  Text(
                    '$bidCount Bids',
                    style: AppTextStyles.bodyStrong.copyWith(color: AppColors.info),
                  ),
              ],
            ),
          ],
        ),
      ).animate(delay: (50 * animationIndex).ms)
       .fadeIn(duration: 300.ms)
       .slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOut),
    );
  }
}
