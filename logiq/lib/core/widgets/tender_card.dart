import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logiq/core/theme/app_colors.dart';
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
    final isLive = tender.status == TenderStatus.stage1 || tender.status == TenderStatus.stage2;
    final statusColor = isLive
        ? AppColors.roseAlert
        : (tender.status == TenderStatus.scheduled ? AppColors.amber : AppColors.secondary);
    final statusBg = isLive
        ? AppColors.roseAlert.withValues(alpha: 0.12)
        : (tender.status == TenderStatus.scheduled ? AppColors.amberSoft : const Color(0xFFEFF6FF));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#TDR-${tender.id ?? "---"}',
                  style: const TextStyle(
                    color: AppColors.slate,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tender.status == TenderStatus.stage2
                            ? Icons.bolt
                            : (tender.status == TenderStatus.stage1 ? Icons.gavel : Icons.schedule),
                        size: 12,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tender.status.label,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tender.shortRoute.isNotEmpty ? tender.shortRoute : '${tender.pickup} → ${tender.drop}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: AppColors.navy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${tender.vehicleType} • ${tender.title}',
                        style: const TextStyle(
                          color: AppColors.slate,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'CEILING CAP',
                      style: TextStyle(
                        color: AppColors.slate,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${tender.ceilingBid.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_outlined, size: 14, color: AppColors.emeraldSuccess),
                    SizedBox(width: 4),
                    Text(
                      'Verified Eligible Fleet',
                      style: TextStyle(
                        color: AppColors.emeraldSuccess,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    if (tender.status == TenderStatus.stage2) {
                      context.push('/tender/${tender.id}/live');
                    } else if (tender.status == TenderStatus.completed) {
                      context.push('/tender/${tender.id}/result');
                    } else if (tender.status == TenderStatus.stage1) {
                      context.push('/tender/${tender.id}/bid');
                    } else {
                      context.push('/tender/${tender.id}');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tender.status == TenderStatus.stage2
                        ? AppColors.navy
                        : (tender.status == TenderStatus.stage1 ? AppColors.emeraldSuccess : AppColors.secondary),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: const Size(0, 34),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    tender.status == TenderStatus.stage2
                        ? 'Enter Stage 2'
                        : (tender.status == TenderStatus.stage1
                            ? 'Place Bid'
                            : (tender.status == TenderStatus.completed ? 'View Result' : 'View Details')),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
