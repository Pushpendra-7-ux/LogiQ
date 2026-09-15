import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auction_provider.dart';
import 'bid_success_overlay.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptic_utils.dart';
import '../../core/theme/app_colors.dart';

class BidConfirmDialog extends StatelessWidget {
  final int tenderId;
  final double amount;
  final int stage;
  const BidConfirmDialog({super.key, required this.tenderId, required this.amount, required this.stage});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('CONFIRM BID', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Are you sure you want to submit:'),
          const SizedBox(height: 12),
          Text(Formatters.currency(amount), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 8),
          const Text('This bid will be officially recorded.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        ElevatedButton(
          onPressed: () async {
            final ap = context.read<AuctionProvider>();
            final ok = await ap.submitBid(tenderId, amount);
            if (!context.mounted) return;
            Navigator.pop(context); // close dialog
            Navigator.pop(context); // close bottom sheet
            if (ok) {
              HapticUtils.bidSubmitted();
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => BidSuccessOverlay(amount: amount),
              );
            } else {
              HapticUtils.error();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ap.error ?? 'Bid rejected'), backgroundColor: AppColors.error),
              );
            }
          },
          child: const Text('SUBMIT'),
        ),
      ],
    );
  }
}