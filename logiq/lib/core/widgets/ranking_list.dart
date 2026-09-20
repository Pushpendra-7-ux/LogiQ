import 'package:flutter/material.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/core/utils/currency_formatter.dart';
import 'package:logiq/core/widgets/rank_badge.dart';
import 'package:logiq/models/auction.dart';

class RankingList extends StatelessWidget {
  final List<RankingEntry> rankings;
  final int? currentTransporterId;
  final bool isBlind;

  const RankingList({
    super.key,
    required this.rankings,
    this.currentTransporterId,
    this.isBlind = false,
  });

  @override
  Widget build(BuildContext context) {
    if (rankings.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        child: Text(
          'No bids placed yet',
          style: AppTextStyles.bodyMuted,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rankings.length,
      separatorBuilder: (_, i) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = rankings[index];
        final isMe = currentTransporterId != null &&
            entry.transporterId == currentTransporterId;

        // In blind mode, mask competitor amounts
        final displayAmount = (isBlind && !isMe)
            ? '••••••'
            : CurrencyFormatter.format(entry.amount);

        final displayName = (isBlind && !isMe)
            ? 'Transporter ${entry.rank}'
            : (isMe ? '${entry.transporterName} (You)' : entry.transporterName);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isMe ? AppColors.electricBlueLight : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isMe ? AppColors.electricBlue : AppColors.cardBorder,
              width: isMe ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              RankBadge(
                rank: entry.rank,
                isHighlighted: isMe,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: isMe
                          ? AppTextStyles.bodyStrong.copyWith(color: AppColors.navy)
                          : AppTextStyles.body.copyWith(color: AppColors.navy),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isMe)
                      Text(
                        'Your Current Rank',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.electricBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                displayAmount,
                style: AppTextStyles.amount.copyWith(
                  fontSize: 18,
                  color: isMe ? AppColors.ink : AppColors.inkSoft,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
