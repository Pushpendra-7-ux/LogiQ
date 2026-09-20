import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/providers/tender_provider.dart';
import 'package:logiq/models/tender.dart';
import 'package:logiq/models/auction.dart';
import 'package:logiq/services/auction_service.dart';

class ActiveTendersUserScreen extends StatefulWidget {
  const ActiveTendersUserScreen({super.key});

  @override
  State<ActiveTendersUserScreen> createState() => _ActiveTendersUserScreenState();
}

class _ActiveTendersUserScreenState extends State<ActiveTendersUserScreen> {
  final Map<int, Auction> _auctions = {};
  final Map<int, List<_RankRow>> _rankings = {};
  bool _isLoading = true;
  Timer? _timer;
  final AuctionService _auctionService = AuctionService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final tenderProvider = context.read<TenderProvider>();
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id;
    if (userId == null) return;

    try {
      await tenderProvider.loadTendersForUser(userId);
      final activeTenders = tenderProvider.activeTenders;

      for (final tender in activeTenders) {
        if (tender.id == null) continue;
        try {
          final auction = await _auctionService.getAuctionByTenderId(tender.id!);
          if (auction != null) {
            _auctions[tender.id!] = auction;
            final stage = auction.status == AuctionStatus.stage2Live ? 2 : 1;
            final bids = await _auctionService.getValidStageBids(auction.id!, stage);
            final names = await _auctionService.getCompanyNames(
              bids.map((b) => b.transporterId).toSet().toList(),
            );
            final rankRows = <_RankRow>[];
            for (var i = 0; i < bids.length && i < 5; i++) {
              final bid = bids[i];
              final isBlind = auction.status == AuctionStatus.stage2Live;
              rankRows.add(_RankRow(
                rank: i + 1,
                name: isBlind ? 'Bidder ${i + 1}' : (names[bid.transporterId] ?? 'Unknown'),
                amount: bid.amount,
                transporterId: bid.transporterId,
              ));
            }
            _rankings[tender.id!] = rankRows;
          }
        } catch (_) {}
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    }
    final parts = amount.toStringAsFixed(0).split('');
    final result = StringBuffer();
    for (var i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 2 == 1 && i < parts.length - 3 ||
          i > 0 && (parts.length - i) == 3) {
        result.write(',');
      }
      result.write(parts[i]);
    }
    return '₹$result';
  }

  String _formatTimeRemaining(DateTime? endTime) {
    if (endTime == null) return "00:00";
    final now = DateTime.now();
    final diff = endTime.difference(now);
    if (diff.isNegative) return "00:00";
    final minutes = diff.inMinutes.toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.currentUser?.name ?? "User";
    final initials = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : "U";

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(userName, initials),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.logiqGreen))
                : RefreshIndicator(
                    color: AppColors.logiqGreen,
                    onRefresh: _loadData,
                    child: _buildBody(),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String userName, String initials) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink),
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.emerald,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            "Active Tenders",
            style: AppTextStyles.h2,
          ),
          const Spacer(),
          Text(
            userName,
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: AppColors.logiqGreen,
            radius: 16,
            child: Text(
              initials,
              style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final tenderProvider = context.watch<TenderProvider>();
    final activeTenders = tenderProvider.activeTenders;

    if (activeTenders.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(
            child: Text(
              "No active tenders right now.",
              style: AppTextStyles.bodyMuted,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: activeTenders.length,
      itemBuilder: (context, index) {
        final tender = activeTenders[index];
        final auction = _auctions[tender.id];
        final rankings = _rankings[tender.id] ?? [];

        return _buildTenderCard(tender, auction, rankings);
      },
    );
  }

  Widget _buildTenderCard(Tender tender, Auction? auction, List<_RankRow> rankings) {
    if (auction == null) {
      return const SizedBox.shrink();
    }

    final isRound1Live = auction.status == AuctionStatus.stage1Live;
    final isRound1Ended = auction.status == AuctionStatus.stage1Completed;
    final isRound2Live = auction.status == AuctionStatus.stage2Live;
    final isCompleted = auction.status == AuctionStatus.completed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isRound1Live || isRound2Live) ...[
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.emerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isRound1Live ? "ROUND 1 • LIVE" : "ROUND 2 • BLIND",
                      style: const TextStyle(
                        color: AppColors.emerald,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: AppColors.ink),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimeRemaining(isRound1Live ? auction.stage1End : auction.stage2End),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ] else if (isRound1Ended) ...[
                const Text(
                  "ROUND 1 ENDED",
                  style: TextStyle(
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                if (rankings.isNotEmpty)
                  Text(
                    "R1 Lowest: ${_formatCurrency(rankings.first.amount)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
              ] else if (isCompleted) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.logiqGreenLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "COMPLETED",
                    style: TextStyle(
                      color: AppColors.logiqGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tender.shortRoute,
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: 12),
          if (isRound1Live || isRound2Live) ...[
            const Divider(color: AppColors.outline),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "RANK & TRANSPORTER",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkSoft,
                  ),
                ),
                const Text(
                  "BID AMOUNT",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRankingsList(rankings, isRound2Live),
          ] else if (isRound1Ended) ...[
            const SizedBox(height: 8),
            const Text(
              "L1–L5 bid privately with masked bids to submit their absolute lowest price.",
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Round 2 Blind Auction starting...'),
                      backgroundColor: AppColors.logiqGreen,
                    ),
                  );
                  _loadData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.logiqGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.visibility_off, color: AppColors.white),
                    SizedBox(width: 8),
                    Text(
                      "Start Round 2 Blind Auction",
                      style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (isCompleted) ...[
            const SizedBox(height: 12),
            if (rankings.isNotEmpty) ...[
              Text(
                "Winner: ${rankings.first.name}",
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                "Final bid: ${_formatCurrency(rankings.first.amount)}",
                style: AppTextStyles.bodyMuted,
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => context.push('/tender/${tender.id}'),
                child: const Text("View Details", style: TextStyle(color: AppColors.logiqGreen, fontWeight: FontWeight.bold)),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildRankingsList(List<_RankRow> rankings, bool isAnonymous) {
    if (rankings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            "No bids yet",
            style: AppTextStyles.bodyMuted,
          ),
        ),
      );
    }

    return Column(
      children: List.generate(rankings.length, (index) {
        final rank = rankings[index];
        final isL1 = index == 0;
        
        final name = isAnonymous ? "Bidder ${index + 1}" : rank.name;
        final label = "L${rank.rank}";
        
        if (isL1) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              border: Border.all(color: const Color(0xFFD1FAE5)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.emerald,
                  radius: 12,
                  child: Text(
                    label,
                    style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Text(
                        "LOWEST BID",
                        style: TextStyle(
                          color: AppColors.emerald,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatCurrency(rank.amount),
                  style: const TextStyle(
                    color: AppColors.emerald,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFF3F4F6),
                      radius: 12,
                      child: Text(
                        label,
                        style: const TextStyle(color: AppColors.inkSoft, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    Text(
                      _formatCurrency(rank.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < rankings.length - 1)
                const Divider(color: AppColors.outline, height: 1),
            ],
          ),
        );
      }),
    );
  }
}

class _RankRow {
  final int rank;
  final String name;
  final double amount;
  final int transporterId;

  const _RankRow({
    required this.rank,
    required this.name,
    required this.amount,
    required this.transporterId,
  });
}
