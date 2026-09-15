import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auction_provider.dart';
import 'bid_confirm_dialog.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_colors.dart';

class BidEntrySheet extends StatefulWidget {
  final int tenderId;
  final int stage;
  const BidEntrySheet({super.key, required this.tenderId, required this.stage});
  @override State<BidEntrySheet> createState() => _BidEntrySheetState();
}

class _BidEntrySheetState extends State<BidEntrySheet> {
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _onContinue() {
    final val = double.tryParse(_amountCtrl.text.replaceAll(',', '').trim());
    if (val == null || val <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }
    final ap = context.read<AuctionProvider>();
    if (widget.stage == 1 && ap.minimumValidBid != null && val > ap.minimumValidBid!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bid must be at most ${Formatters.currency(ap.minimumValidBid!)}'), backgroundColor: AppColors.error),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => BidConfirmDialog(tenderId: widget.tenderId, amount: val, stage: widget.stage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AuctionProvider>();
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('ENTER YOUR BID', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              prefixText: '₹ ',
              prefixStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
              hintText: '0',
            ),
          ),
          const SizedBox(height: 12),
          if (widget.stage == 1 && ap.minimumValidBid != null)
            Text('Maximum valid bid: ${Formatters.currency(ap.minimumValidBid!)}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600))
          else if (widget.stage == 2)
            const Text('Enter your single best confidential price.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _onContinue,
            child: const Text('CONTINUE'),
          ),
        ],
      ),
    );
  }
}