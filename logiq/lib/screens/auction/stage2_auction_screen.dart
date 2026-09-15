import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auction_provider.dart';
import '../../widgets/common/countdown_timer.dart';
import '../../widgets/common/connection_indicator.dart';
import 'bid_confirm_dialog.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_colors.dart';

class Stage2AuctionScreen extends StatefulWidget {
  final int tenderId;
  const Stage2AuctionScreen({super.key, required this.tenderId});
  @override State<Stage2AuctionScreen> createState() => _Stage2AuctionScreenState();
}

class _Stage2AuctionScreenState extends State<Stage2AuctionScreen> {
  final _amountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final ap = context.read<AuctionProvider>();
    ap.loadAuctionStatus(widget.tenderId);
    ap.connectWebSocket(widget.tenderId);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    context.read<AuctionProvider>().disconnectWebSocket();
    super.dispose();
  }

  void _submit() {
    final val = double.tryParse(_amountCtrl.text.replaceAll(',', '').trim());
    if (val == null || val <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }
    showDialog(
      context: context,
      builder: (_) => BidConfirmDialog(tenderId: widget.tenderId, amount: val, stage: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AuctionProvider>();
    if (ap.status == 'STAGE_2_COMPLETED' || ap.status == 'WINNER_FINALIZED' || ap.status == 'COMPLETED') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/auction/${widget.tenderId}/result');
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('FINAL AUCTION'),
        backgroundColor: AppColors.blindPurple,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ConnectionIndicator(isConnected: ap.isConnected),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timer
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('TIME REMAINING', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    CountdownTimer(remainingSeconds: ap.remainingSeconds),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Submit your best price.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (ap.myBid != null)
              Card(
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Your recorded bid:', style: TextStyle(color: Colors.grey)),
                      Text(Formatters.currency(ap.myBid!), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                prefixText: '₹ ',
                prefixStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.blindPurple),
                hintText: '0',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.blindPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('SUBMIT FINAL BID', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            // Privacy notice
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.lock_outline, color: AppColors.blindPurple, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your bid is completely private. Other participants\' bids, rankings, and the current lowest quote are strictly hidden. Lowest Stage-2 bid automatically wins.',
                    style: TextStyle(color: Colors.grey, height: 1.4, fontSize: 13),
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