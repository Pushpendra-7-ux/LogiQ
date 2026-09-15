import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auction_provider.dart';
import '../../widgets/common/countdown_timer.dart';
import '../../widgets/common/connection_indicator.dart';
import '../../widgets/auction/rank_badge.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_colors.dart';

class TenderMonitorScreen extends StatefulWidget {
  final int tenderId;
  const TenderMonitorScreen({super.key, required this.tenderId});
  @override State<TenderMonitorScreen> createState() => _TenderMonitorScreenState();
}

class _TenderMonitorScreenState extends State<TenderMonitorScreen> {
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

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AuctionProvider>();
    final isStage2 = ap.stage == 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(isStage2 ? 'Final Auction (Blind)' : 'Live Stage 1 Auction'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ConnectionIndicator(isConnected: ap.isConnected),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: isStage2 ? AppColors.blindPurple.withValues(alpha: 0.08) : AppColors.primary.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(isStage2 ? 'STAGE 2 — BLIND AUCTION' : 'STAGE 1 — TRANSPARENT AUCTION',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isStage2 ? AppColors.blindPurple : AppColors.primary, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  CountdownTimer(remainingSeconds: ap.remainingSeconds),
                  const SizedBox(height: 8),
                  Text('Status: ${ap.status}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (isStage2) ...[
            // Tender Maker Stage 2 Blind View: strictly NO bids, NO rankings, NO leader
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: const [
                    Icon(Icons.lock, size: 48, color: AppColors.blindPurple),
                    SizedBox(height: 12),
                    Text('Blind Stage in Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Top 5 transporters are submitting their final bids privately. All bid amounts, leader status, and rankings are confidential until stage completion.',
                        textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.4)),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Stage 1 Ranking view
            const Text('Live Rankings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (ap.rankings.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No bids submitted yet.', style: TextStyle(color: Colors.grey))))
            else
              ...ap.rankings.map((r) => Card(
                    child: ListTile(
                      leading: RankBadge(rank: r.rank, size: 40),
                      title: Text(r.transporterName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text(Formatters.currency(r.amount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                  )),
          ],
          const SizedBox(height: 32),
          if (ap.status == 'WINNER_FINALIZED' || ap.status == 'COMPLETED')
            ElevatedButton(
              onPressed: () => context.push('/auction/${widget.tenderId}/result'),
              child: const Text('VIEW FINAL WINNER & RESULTS'),
            ),
        ],
      ),
    );
  }
}