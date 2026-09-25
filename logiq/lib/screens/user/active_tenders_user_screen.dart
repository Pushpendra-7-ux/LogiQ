import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/providers/tender_provider.dart';
import 'package:logiq/models/tender.dart';
import 'package:logiq/models/material.dart';
import 'package:logiq/models/auction.dart';
import 'package:logiq/models/bid.dart';
import 'package:logiq/services/auction_service.dart';
import 'package:intl/intl.dart';

class ActiveTendersUserScreen extends StatefulWidget {
  const ActiveTendersUserScreen({super.key});

  @override
  State<ActiveTendersUserScreen> createState() => _ActiveTendersUserScreenState();
}

class _ActiveTendersUserScreenState extends State<ActiveTendersUserScreen> {
  final Map<int, Auction> _auctions = {};
  final Map<int, List<_RankRow>> _rankings = {};
  final Map<int, List<MaterialItem>> _materials = {};
  bool _isLoading = true;
  Timer? _timer;
  final AuctionService _auctionService = AuctionService.instance;
  final DateFormat _windowFormat = DateFormat('dd MMM, hh:mm a');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      await _syncAuctionsAndRankings();
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
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      await tenderProvider.loadTendersForUser(userId);
      await _syncAuctionsAndRankings();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncAuctionsAndRankings() async {
    final tenderProvider = context.read<TenderProvider>();
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id;
    if (userId != null) {
      await tenderProvider.checkAutoPublish(userId);
      await tenderProvider.loadTendersForUser(userId, silent: true);
    }
    final activeTenders = tenderProvider.activeTenders;

    for (final tender in activeTenders) {
      if (tender.id == null) continue;
      try {
        _materials[tender.id!] = await tenderProvider.materialsFor(tender.id!);
        await _auctionService.checkAndTransitionAuction(tender.id!);
        var auction = await _auctionService.getAuctionByTenderId(tender.id!);
        if (auction == null) {
          final now = DateTime.now();
          final effectiveStart = tender.biddingStart;
          final effectiveEnd = tender.softEnd;
          final isFuture = effectiveStart.isAfter(now);
          final newAuction = Auction(
            tenderId: tender.id!,
            currentStage: 1,
            stage1Start: effectiveStart,
            stage1End: effectiveEnd,
            stage2Start: effectiveEnd,
            stage2End: effectiveEnd.add(const Duration(minutes: 5)),
            status: isFuture ? AuctionStatus.scheduled : AuctionStatus.stage1Live,
          );
          await _auctionService.saveAuction(newAuction);
          auction = await _auctionService.getAuctionByTenderId(tender.id!);
        }

        if (auction != null && auction.id != null) {
          _auctions[tender.id!] = auction;
          final stage = auction.status == AuctionStatus.stage2Live ? 2 : 1;
          final bids = await _auctionService.getValidStageBids(auction.id!, stage);

          final seen = <int>{};
          final uniqueBids = <Bid>[];
          for (final b in bids) {
            if (seen.add(b.transporterId)) {
              uniqueBids.add(b);
            }
          }
          final names = await _auctionService.getCompanyNames(
            uniqueBids.map((b) => b.transporterId).toList(),
          );
          final rankRows = <_RankRow>[];
          for (var i = 0; i < uniqueBids.length && i < 5; i++) {
            final bid = uniqueBids[i];
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
    if (diff.inDays >= 1) {
      final d = diff.inDays;
      final h = diff.inHours % 24;
      return h > 0 ? '${d}d ${h}h' : '${d}d';
    }
    if (diff.inHours >= 1) {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
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
        final mats = _materials[tender.id] ?? [];
        return _buildTenderCard(tender, auction, rankings, mats);
      },
    );
  }

  Widget _buildTenderCard(
    Tender tender,
    Auction? auction,
    List<_RankRow> rankings,
    List<MaterialItem> materials,
  ) {
    final now = DateTime.now();
    final effectiveStage1Start = auction?.stage1Start ?? tender.biddingStart;
    final effectiveStage1End = auction?.stage1End ?? tender.softEnd;
    final effectiveStage2End = auction?.stage2End ?? tender.hardStop;
    final isScheduled = (auction?.status == AuctionStatus.scheduled || tender.status == TenderStatus.scheduled) && now.isBefore(effectiveStage1Start);
    final isPastStage1End = now.isAfter(effectiveStage1End);
    final isRound1Live = !isScheduled && (auction == null || auction.status == AuctionStatus.stage1Live) && !isPastStage1End;
    final isRound1Ended = !isScheduled && ((auction != null && auction.status == AuctionStatus.stage1Completed) || isPastStage1End);
    final isRound2Live = auction?.status == AuctionStatus.stage2Live;
    final isCompleted = auction?.status == AuctionStatus.completed || tender.status == TenderStatus.completed;

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
                if (isScheduled)
                  _buildStageChip('SCHEDULED • ROUND 1', Colors.blue.shade700, Colors.blue.shade50, Colors.blue.shade200)
                else if (isRound1Live)
                  _buildStageChip('STAGE 1 • LIVE AUCTION', AppColors.logiqGreen, AppColors.logiqGreenBg, AppColors.logiqGreenBorder)
                else if (isRound2Live)
                  _buildStageChip('STAGE 2 • BLIND AUCTION', Colors.deepPurple, Colors.deepPurple.shade50, Colors.deepPurple.shade200)
                else if (isRound1Ended)
                  _buildStageChip('STAGE 1 COMPLETED', Colors.orange.shade800, Colors.orange.shade50, Colors.orange.shade200)
                else if (isCompleted)
                  _buildStageChip('AUCTION COMPLETED', AppColors.logiqGreen, AppColors.logiqGreenBg, AppColors.logiqGreenBorder),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isScheduled
                          ? Colors.blue.shade200
                          : isRound1Ended
                              ? Colors.orange.shade300
                              : isRound2Live
                                  ? Colors.deepPurple.shade200
                                  : AppColors.outline,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isScheduled
                            ? Icons.schedule
                            : isRound2Live
                                ? Icons.visibility_off_outlined
                                : Icons.timer_outlined,
                        size: 14,
                        color: isScheduled
                            ? Colors.blue.shade800
                            : isRound1Ended
                                ? Colors.orange.shade800
                                : isRound2Live
                                    ? Colors.deepPurple
                                    : AppColors.ink,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isScheduled
                            ? 'Starts ${_formatTimeRemaining(effectiveStage1Start)}'
                            : isRound1Live
                                ? _formatTimeRemaining(effectiveStage1End)
                                : isRound2Live
                                    ? _formatTimeRemaining(effectiveStage2End)
                                    : isRound1Ended
                                        ? '00:00 • Time Up'
                                        : 'Closed',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isScheduled
                              ? Colors.blue.shade900
                              : isRound1Ended
                                  ? Colors.orange.shade900
                                  : isRound2Live
                                      ? Colors.deepPurple
                                      : AppColors.ink,
                          fontSize: 12,
                        ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(tender.title, style: AppTextStyles.h3),
                    ),
                    if (tender.id != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCanvas,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: Text(
                          '#TND-${tender.id}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkSoft),
                        ),
                      ),
                  ],
                ),
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
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isScheduled ? Colors.blue.shade50 : AppColors.surfaceCanvas,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isScheduled ? Colors.blue.shade200 : AppColors.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isScheduled ? Icons.schedule : Icons.timer_outlined,
                        size: 13,
                        color: isScheduled ? Colors.blue.shade800 : AppColors.logiqGreen,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isScheduled
                              ? 'Scheduled: ${_windowFormat.format(effectiveStage1Start)} – ${_windowFormat.format(effectiveStage1End)}'
                              : 'Bidding Window: ${_windowFormat.format(effectiveStage1Start)} – ${_windowFormat.format(effectiveStage1End)}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isScheduled ? Colors.blue.shade900 : AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoBadge(Icons.local_shipping_outlined, tender.vehicleType),
                    _buildInfoBadge(
                      Icons.calendar_today_outlined,
                      '${tender.deliveryStart.day}/${tender.deliveryStart.month} - ${tender.deliveryEnd.day}/${tender.deliveryEnd.month}',
                    ),
                    if (materials.isNotEmpty)
                      _buildInfoBadge(
                        Icons.inventory_2_outlined,
                        '${materials.first.quantity.toInt()} ${materials.first.unit} • ${materials.first.description}',
                      ),
                    if (tender.remarks.isNotEmpty)
                      _buildInfoBadge(Icons.notes_outlined, tender.remarks),
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
                        hasBids ? _formatCurrency(lowestBid!) : (isScheduled ? 'Scheduled' : 'Waiting for bids'),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isRound2Live ? Icons.visibility_off_outlined : Icons.leaderboard_outlined,
                          size: 14,
                          color: isRound2Live ? Colors.deepPurple : AppColors.inkSoft,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isRound2Live
                              ? 'ROUND 2 SEALED BIDS'
                              : isRound1Ended
                                  ? 'QUALIFYING LEADERBOARD (L1–L5)'
                                  : 'LIVE LEADERBOARD (L1–L5)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isRound2Live ? Colors.deepPurple : AppColors.inkSoft,
                            letterSpacing: 0.5,
                          ),
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
                _buildRankingsList(
                  rankings,
                  isRound2Live,
                  tender.ceilingBid,
                  isScheduled: isScheduled,
                  scheduledStart: effectiveStage1Start,
                ),
                if (isRound1Ended && !isRound2Live && !isCompleted) ...[
                  const SizedBox(height: 14),
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
                            'Stage 1 ended. Top qualifying carriers (L1–L5) above are locked. Proceed to Round 2 Blind Auction.',
                            style: TextStyle(fontSize: 12, color: Colors.orange.shade900, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final auth = context.read<AuthProvider>();
                        final userId = auth.currentUser?.id;
                        if (userId == null) return;
                        final success = await context.read<TenderProvider>().startRound2BlindAuction(
                          tenderId: tender.id!,
                          userId: userId,
                        );
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Stage 2 Blind Auction is now LIVE!'),
                              backgroundColor: AppColors.logiqGreen,
                            ),
                          );
                          await _loadData();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.logiqGreen,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.visibility_off, size: 18),
                      label: const Text(
                        'GO FOR ROUND 2 BLIND AUCTION',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ] else if (isRound2Live) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.deepPurple.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline, color: Colors.deepPurple.shade700, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Round 2 Blind Auction in progress. Carrier names and bids are sealed until auction close.',
                            style: TextStyle(fontSize: 12, color: Colors.deepPurple.shade900, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (isCompleted) ...[
                  const SizedBox(height: 14),
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

  Widget _buildRankingsList(
    List<_RankRow> rankings,
    bool isAnonymous,
    double ceilingBid, {
    bool isScheduled = false,
    DateTime? scheduledStart,
  }) {
    if (rankings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCanvas,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          children: [
            Icon(isScheduled ? Icons.schedule : Icons.hourglass_empty_rounded, size: 28, color: AppColors.inkSoft),
            const SizedBox(height: 8),
            Text(isScheduled ? 'Bidding Scheduled' : 'Waiting for Carrier Bids', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 4),
            Text(
              isScheduled && scheduledStart != null
                  ? 'Bidding will open at ${scheduledStart.hour.toString().padLeft(2, '0')}:${scheduledStart.minute.toString().padLeft(2, '0')} below the cap of ₹${ceilingBid.toInt()}.'
                  : 'Participating carriers will start bidding below the cap of ₹${ceilingBid.toInt()}.',
              style: const TextStyle(fontSize: 12, color: AppColors.inkFaint),
              textAlign: TextAlign.center,
            ),
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
