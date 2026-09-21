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
                name: isBlind ? 'Bidder ${i + 1}' : (names[bid.transporterId] ?? 'Carrier ${bid.transporterId}'),
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
    final integerPart = amount.toInt().toString();
    if (integerPart.length <= 3) return '₹$integerPart';
    final lastThree = integerPart.substring(integerPart.length - 3);
    final otherDigits = integerPart.substring(0, integerPart.length - 3);
    final formattedOther = otherDigits.replaceAllMapped(
      RegExp(r'(\d+?)(?=(\d\d)+$)'),
      (Match m) => '${m[1]},',
    );
    return '₹$formattedOther,$lastThree';
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
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
            width: 32,
            height: 32,
            decoration: const BoxDecoration(color: AppColors.logiqGreen, shape: BoxShape.circle),
            child: const Icon(Icons.cell_tower, color: AppColors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Active Tenders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.logiqGreenBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.logiqGreenBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: AppColors.logiqGreenLight, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'LIVE',
                          style: TextStyle(color: AppColors.logiqGreen, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Text('Real-time reverse auction bids', style: TextStyle(fontSize: 11, color: AppColors.inkSoft)),
            ],
          ),
          const Spacer(),
          InkWell(
            onTap: () => context.push('/profile'),
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.logiqGreenBg,
                  radius: 16,
                  child: Text(
                    initials,
                    style: const TextStyle(color: AppColors.logiqGreen, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: AppColors.logiqGreenBg, shape: BoxShape.circle),
                child: const Icon(Icons.cell_tower, size: 48, color: AppColors.logiqGreen),
              ),
              const SizedBox(height: 24),
              const Text('No Active Tenders', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text(
                'Live reverse auctions will appear here once tenders are published.',
                style: AppTextStyles.bodyMuted.copyWith(color: AppColors.inkFaint),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/tender/create'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.logiqGreen,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Create Tender', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

    final hasBids = rankings.isNotEmpty;
    final lowestBid = hasBids ? rankings.first.amount : null;
    final savings = hasBids ? (tender.ceilingBid - lowestBid!).clamp(0.0, double.infinity) : 0.0;
    final savingsPercent = hasBids && tender.ceilingBid > 0 ? (savings / tender.ceilingBid * 100) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceCanvas,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: AppColors.outline)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isRound1Live)
                  _buildStageChip('STAGE 1 • LIVE AUCTION', AppColors.logiqGreen, AppColors.logiqGreenBg, AppColors.logiqGreenBorder)
                else if (isRound2Live)
                  _buildStageChip('STAGE 2 • BLIND AUCTION', Colors.deepPurple, Colors.deepPurple.shade50, Colors.deepPurple.shade200)
                else if (isRound1Ended)
                  _buildStageChip('STAGE 1 COMPLETED', Colors.orange.shade800, Colors.orange.shade50, Colors.orange.shade200)
                else if (isCompleted)
                  _buildStageChip('AUCTION COMPLETED', AppColors.logiqGreen, AppColors.logiqGreenBg, AppColors.logiqGreenBorder),
                if (isRound1Live || isRound2Live)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: AppColors.ink),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimeRemaining(isRound1Live ? auction.stage1End : auction.stage2End),
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tender.title, style: AppTextStyles.h3),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCanvas,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trip_origin, size: 14, color: AppColors.logiqGreen),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          tender.pickup,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.ink),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, size: 14, color: AppColors.inkSoft),
                      ),
                      const Icon(Icons.location_on, size: 14, color: AppColors.danger),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          tender.drop,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.ink),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoBadge(Icons.local_shipping_outlined, tender.vehicleType),
                    const SizedBox(width: 8),
                    _buildInfoBadge(Icons.calendar_today_outlined, '${tender.deliveryStart.day}/${tender.deliveryStart.month} - ${tender.deliveryEnd.day}/${tender.deliveryEnd.month}'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricBox(
                        'Cap Price',
                        _formatCurrency(tender.ceilingBid),
                        AppColors.inkSoft,
                        AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricBox(
                        'Current L1',
                        hasBids ? _formatCurrency(lowestBid!) : 'No bids',
                        hasBids ? AppColors.logiqGreen : AppColors.inkSoft,
                        hasBids ? AppColors.logiqGreen : AppColors.inkSoft,
                        highlight: hasBids,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricBox(
                        'Savings',
                        hasBids ? '${savingsPercent.toStringAsFixed(1)}%' : '0%',
                        hasBids ? AppColors.logiqGreen : AppColors.inkSoft,
                        hasBids ? AppColors.logiqGreen : AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isRound1Live || isRound2Live) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.leaderboard_outlined, size: 14, color: AppColors.inkSoft),
                          SizedBox(width: 6),
                          Text(
                            'LIVE LEADERBOARD',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.inkSoft, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      Text(
                        'Min decr: ₹${tender.priceDifference.toInt()}',
                        style: const TextStyle(fontSize: 11, color: AppColors.inkSoft, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildRankingsList(rankings, isRound2Live, tender.ceilingBid),
                ] else if (isRound1Ended) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade800, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Stage 1 ended. Top qualifying carriers will now submit blind sealed bids in Stage 2.',
                            style: TextStyle(fontSize: 12, color: Colors.orange.shade900, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Stage 2 Blind Auction starting...'),
                            backgroundColor: AppColors.logiqGreen,
                          ),
                        );
                        _loadData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.logiqGreen,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.visibility_off, size: 18),
                      label: const Text('Start Stage 2 Blind Auction', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                ] else if (isCompleted) ...[
                  if (hasBids)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.logiqGreenBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.logiqGreenBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events, color: AppColors.logiqGreen, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Winning Carrier: ${rankings.first.name}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                Text('Winning Bid: ${_formatCurrency(rankings.first.amount)} • Total Saved: ${_formatCurrency(savings)}', style: const TextStyle(fontSize: 12, color: AppColors.logiqGreen)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.push('/tender/${tender.id}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.logiqGreen,
                      side: const BorderSide(color: AppColors.logiqGreen),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('View Tender Details & Bids →', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageChip(String label, Color color, Color bg, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.inkSoft),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, Color labelColor, Color valueColor, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? AppColors.logiqGreenBg : AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: highlight ? AppColors.logiqGreenBorder : AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: labelColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildRankingsList(List<_RankRow> rankings, bool isAnonymous, double ceilingBid) {
    if (rankings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surfaceCanvas,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.outline),
        ),
        child: const Column(
          children: [
            Icon(Icons.hourglass_empty_rounded, size: 24, color: AppColors.inkSoft),
            SizedBox(height: 6),
            Text('No bids submitted yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
            Text('Carriers will bid below the ceiling cap.', style: TextStyle(fontSize: 11, color: AppColors.inkFaint)),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(rankings.length, (index) {
        final rank = rankings[index];
        final isL1 = index == 0;
        final name = isAnonymous ? "Bidder ${index + 1}" : rank.name;

        if (isL1) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.logiqGreenBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.logiqGreenBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.logiqGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('L1', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink)),
                      const Text('BEST OFFER', style: TextStyle(color: AppColors.logiqGreen, fontSize: 10, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                Text(
                  _formatCurrency(rank.amount),
                  style: const TextStyle(color: AppColors.logiqGreen, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final diff = rank.amount - rankings.first.amount;

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceCanvas,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('L${rank.rank}', style: const TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w700, fontSize: 11)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.ink)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatCurrency(rank.amount), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.ink)),
                  Text('+${_formatCurrency(diff)}', style: const TextStyle(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.w600)),
                ],
              ),
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
