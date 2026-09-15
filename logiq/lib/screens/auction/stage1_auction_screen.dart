import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auction_provider.dart';
import '../../widgets/common/countdown_timer.dart';
import '../../widgets/common/connection_indicator.dart';
import '../../widgets/auction/rank_badge.dart';
import '../../widgets/auction/extension_banner.dart';
import 'bid_entry_sheet.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_colors.dart';

class Stage1AuctionScreen extends StatefulWidget {
  final int tenderId;
  const Stage1AuctionScreen({super.key, required this.tenderId});
  @override State<Stage1AuctionScreen> createState() => _Stage1AuctionScreenState();
}

class _Stage1AuctionScreenState extends State<Stage1AuctionScreen> {
  @override
  void initState() {
    super.initState();
    final ap = context.read<AuctionProvider>();
    ap.loadAuctionStatus(widget.tenderId);
    ap.connectWebSocket(widget.tenderId);
  }

  @override
  void dispose() {
    context.read<AuctionProvider>().disconnectWebSocket();
    super.dispose();
  }

  void _openBidSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BidEntrySheet(tenderId: widget.tenderId, stage: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AuctionProvider>();
    if (ap.status == 'STAGE_1_COMPLETED' || ap.status.contains('STAGE_2')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/auction/${widget.tenderId}/transition');
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('LIVE AUCTION'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ConnectionIndicator(isConnected: ap.isConnected),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Timer card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      const Text('TIME REMAINING', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      CountdownTimer(remainingSeconds: ap.remainingSeconds),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Stats grid: Your Rank, Your Bid, Current L1, Minimum Valid Bid
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      title: 'YOUR RANK',
                      value: ap.myRank ?? '—',
                      color: ap.myRank == 'L1' ? AppColors.rankL1 : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      title: 'YOUR BID',
                      value: ap.myBid != null ? Formatters.currency(ap.myBid!) : '—',
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      title: 'CURRENT L1',
                      value: ap.currentL1 != null ? Formatters.currency(ap.currentL1!) : '—',
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      title: 'MINIMUM BID',
                      value: ap.minimumValidBid != null ? Formatters.currency(ap.minimumValidBid!) : 'Any',
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _openBidSheet,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('BID NOW', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Live Rankings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (ap.rankings.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No bids yet. Submit first bid!', style: TextStyle(color: Colors.grey))))
              else
                ...ap.rankings.map((r) => Card(
                      child: ListTile(
                        leading: RankBadge(rank: r.rank, size: 40),
                        title: Text(r.transporterName),
                        trailing: Text(Formatters.currency(r.amount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                    )),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ExtensionBanner(extensionMinutes: 5, visible: ap.auctionExtended),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _StatBox({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(value, key: ValueKey(value), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}