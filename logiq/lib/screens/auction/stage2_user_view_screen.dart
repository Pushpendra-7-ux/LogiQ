import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auction_provider.dart';
import '../../widgets/common/countdown_timer.dart';
import '../../widgets/common/connection_indicator.dart';
import '../../core/theme/app_colors.dart';

class Stage2UserViewScreen extends StatefulWidget {
  final int tenderId;
  const Stage2UserViewScreen({super.key, required this.tenderId});
  @override State<Stage2UserViewScreen> createState() => _Stage2UserViewScreenState();
}

class _Stage2UserViewScreenState extends State<Stage2UserViewScreen> {
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
    if (ap.status == 'WINNER_FINALIZED' || ap.status == 'COMPLETED') {
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.liveGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                      child: const Text('STATUS: LIVE', style: TextStyle(color: AppColors.liveGreen, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    const Text('Top 5 Qualifiers Competing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    CountdownTimer(remainingSeconds: ap.remainingSeconds),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Icon(Icons.shield_outlined, size: 64, color: AppColors.blindPurple),
            const SizedBox(height: 16),
            const Text('Strict Privacy Mode', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'As Tender Maker, all bid amounts and rankings are withheld to maintain total fairness and integrity until the auction reaches conclusion.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}