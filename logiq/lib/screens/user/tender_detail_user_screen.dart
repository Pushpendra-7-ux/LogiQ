import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/utils/formatters.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/providers/tender_provider.dart';
import 'package:logiq/providers/auction_provider.dart';
import 'package:logiq/models/tender.dart';
import 'package:logiq/models/material.dart';
import 'package:logiq/models/auction.dart';
import 'package:logiq/models/bid.dart';
import 'package:logiq/services/auction_service.dart';
import 'package:logiq/services/tender_service.dart';

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

class TenderDetailUserScreen extends StatefulWidget {
  final int tenderId;

  const TenderDetailUserScreen({super.key, required this.tenderId});

  @override
  State<TenderDetailUserScreen> createState() => _TenderDetailUserScreenState();
}

class _TenderDetailUserScreenState extends State<TenderDetailUserScreen> {
  bool _isLoading = true;
  List<MaterialItem> _materials = [];
  bool _isGstVerified = true;
  int _participantCount = 0;
  Auction? _auction;
  List<_RankRow> _rankings = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _refreshAuctionData();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final tenderProv = context.read<TenderProvider>();
    final auctionProv = context.read<AuctionProvider>();

    _materials = await tenderProv.materialsFor(widget.tenderId);
    _participantCount = await tenderProv.participantCountFor(widget.tenderId);
    await auctionProv.loadAuction(widget.tenderId);
    await _refreshAuctionData();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshAuctionData() async {
    try {
      await AuctionService.instance.checkAndTransitionAuction(widget.tenderId);
      var auction = await AuctionService.instance.getAuctionByTenderId(widget.tenderId);
      if (auction == null) {
        final tender = await TenderService.instance.getTenderById(widget.tenderId);
        if (tender != null && tender.status != TenderStatus.draft) {
          final now = DateTime.now();
          final effectiveStart = tender.biddingStart;
          final effectiveEnd = tender.softEnd;
          final isFuture = effectiveStart.isAfter(now);
          final newAuction = Auction(
            tenderId: widget.tenderId,
            currentStage: 1,
            stage1Start: effectiveStart,
            stage1End: effectiveEnd,
            stage2Start: effectiveEnd,
            stage2End: effectiveEnd.add(const Duration(minutes: 5)),
            status: isFuture ? AuctionStatus.scheduled : AuctionStatus.stage1Live,
          );
          await AuctionService.instance.saveAuction(newAuction);
          auction = await AuctionService.instance.getAuctionByTenderId(widget.tenderId);
        }
      }

      if (auction != null && auction.id != null) {
        _auction = auction;
        final stage = (auction.status == AuctionStatus.stage2Live) ? 2 : 1;
        final bids = await AuctionService.instance.getValidStageBids(auction.id!, stage);
        final seen = <int>{};
        final uniqueBids = <Bid>[];
        for (final b in bids) {
          if (seen.add(b.transporterId)) {
            uniqueBids.add(b);
          }
        }
        final names = await AuctionService.instance.getCompanyNames(
          uniqueBids.map((b) => b.transporterId).toList(),
        );
        final rankRows = <_RankRow>[];
        for (var i = 0; i < uniqueBids.length && i < 5; i++) {
          final b = uniqueBids[i];
          final isBlind = auction.status == AuctionStatus.stage2Live;
          rankRows.add(_RankRow(
            rank: i + 1,
            name: isBlind ? 'Bidder ${i + 1}' : (names[b.transporterId] ?? 'Carrier ${b.transporterId}'),
            amount: b.amount,
            transporterId: b.transporterId,
          ));
        }
        if (mounted) {
          setState(() {
            _rankings = rankRows;
          });
        }
      }
    } catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    final tenderProv = context.watch<TenderProvider>();
    final tender = tenderProv.tenderById(widget.tenderId);

    if (_isLoading || tender == null) {
      return const Scaffold(
        backgroundColor: AppColors.surfaceCanvas,
        body: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
      );
    }

    final tenderRef = '#TDR-${tender.id}';
    final cargoName = _materials.isNotEmpty ? _materials.first.description : 'General Freight Cargo';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceCanvas,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusBadgeRow(tenderRef, _auction),
                          const SizedBox(height: 12),
                          _buildRouteLoadCard(tender, cargoName),
                          const SizedBox(height: 12),
                          _buildAuctionParamsGrid(tender),
                          const SizedBox(height: 12),
                          _buildBiddingScheduleCard(tender, _auction),
                          const SizedBox(height: 12),
                          _buildLiveLeaderboardCard(tender, _auction, _rankings),
                          const SizedBox(height: 12),
                          _buildCarrierInvitesCard(tender, _participantCount),
                          const SizedBox(height: 12),
                          _buildComplianceToggleCard(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildStickyBottomBar(context, tender, _auction),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 22, color: AppColors.surfaceNavy),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.logiqGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.local_shipping_outlined, size: 16, color: Colors.white),
              ),
              Container(
                height: 16,
                width: 1,
                color: AppColors.borderSubtle,
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              const Text(
                'Tender Details',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.surfaceNavy,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => context.push('/profile'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.surfaceNavy,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 17, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadgeRow(String tenderRef, Auction? auction) {
    final now = DateTime.now();
    final isRound1Live = auction?.status == AuctionStatus.stage1Live && (auction != null && !now.isAfter(auction.stage1End));
    final isRound1Ended = auction?.status == AuctionStatus.stage1Completed ||
        (auction?.status == AuctionStatus.stage1Live && (auction != null && now.isAfter(auction.stage1End)));
    final isRound2Live = auction?.status == AuctionStatus.stage2Live;
    final isCompleted = auction?.status == AuctionStatus.completed;

    String badgeLabel = 'ACTIVE TENDER';
    Color badgeColor = AppColors.logiqGreen;
    if (isRound1Live) {
      badgeLabel = 'STAGE 1 LIVE';
      badgeColor = AppColors.logiqGreen;
    } else if (isRound1Ended) {
      badgeLabel = 'STAGE 1 ENDED';
      badgeColor = Colors.orange.shade800;
    } else if (isRound2Live) {
      badgeLabel = 'STAGE 2 BLIND AUCTION';
      badgeColor = Colors.deepPurple;
    } else if (isCompleted) {
      badgeLabel = 'COMPLETED';
      badgeColor = AppColors.logiqGreen;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                tenderRef,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.surfaceNavy,
                ),
              ),
              const Text(' · ', style: TextStyle(color: AppColors.inkSoft)),
              Text(
                badgeLabel,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: badgeColor,
                ),
              ),
            ],
          ),
        ),
        const Text(
          'REVERSE AUCTION',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.inkSoft,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteLoadCard(Tender tender, String cargoName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ORIGIN',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tender.pickup,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.surfaceNavy,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward, size: 20, color: AppColors.inkSoft),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'DESTINATION',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tender.drop,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.surfaceNavy,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cargoName,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.surfaceNavy,
                ),
              ),
              Text(
                'Vehicle: ${tender.vehicleType}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionParamsGrid(Tender tender) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildParamCard('CEILING BID (CAP)', _formatCurrency(tender.ceilingBid), 'Max price allowed', Icons.arrow_downward_rounded, AppColors.logiqGreen),
        _buildParamCard('MIN DECREMENT', '₹${tender.priceDifference.toInt()}', 'Per bid step', Icons.unfold_more_rounded, AppColors.secondary),
        _buildParamCard('DELIVERY START', Formatters.formatDate(tender.deliveryStart), 'Required pickup', Icons.calendar_today_rounded, AppColors.surfaceNavy),
        _buildParamCard('DELIVERY END', Formatters.formatDate(tender.deliveryEnd), 'Expected delivery', Icons.event_available_rounded, AppColors.surfaceNavy),
      ],
    );
  }

  Widget _buildParamCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.inkSoft,
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiddingScheduleCard(Tender tender, Auction? auction) {
    final now = DateTime.now();
    final isRound1Live = auction?.status == AuctionStatus.stage1Live && (auction != null && !now.isAfter(auction.stage1End));
    final isRound1Ended = auction?.status == AuctionStatus.stage1Completed ||
        (auction?.status == AuctionStatus.stage1Live && (auction != null && now.isAfter(auction.stage1End)));
    final isRound2Live = auction?.status == AuctionStatus.stage2Live;
    final isCompleted = auction?.status == AuctionStatus.completed || tender.status == TenderStatus.completed;

    String statusText = 'Scheduled';
    Color statusColor = AppColors.inkSoft;
    Color statusBg = AppColors.surfaceCanvas;

    if (isRound1Live) {
      statusText = 'Stage 1 Live';
      statusColor = AppColors.logiqGreenDark;
      statusBg = AppColors.logiqGreenBg;
    } else if (isRound1Ended) {
      statusText = 'Stage 1 Ended • L1–L5 Ready';
      statusColor = Colors.orange.shade900;
      statusBg = Colors.orange.shade50;
    } else if (isRound2Live) {
      statusText = 'Stage 2 Blind Auction Live';
      statusColor = Colors.deepPurple;
      statusBg = Colors.deepPurple.shade50;
    } else if (isCompleted) {
      statusText = 'Auction Completed';
      statusColor = AppColors.logiqGreenDark;
      statusBg = AppColors.logiqGreenBg;
    }

    String countdown = '00:00';
    if (auction != null) {
      DateTime? targetEnd = isRound1Live ? auction.stage1End : (isRound2Live ? auction.stage2End : null);
      if (targetEnd != null) {
        final rem = targetEnd.difference(now);
        if (!rem.isNegative) {
          final m = rem.inMinutes;
          final s = rem.inSeconds % 60;
          countdown = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
        }
      }
    }

    final dateFormat = DateFormat('hh:mm a, dd MMM');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.schedule_outlined, size: 18, color: AppColors.logiqGreen),
                  SizedBox(width: 8),
                  Text(
                    'Bidding Schedule & Timing',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.surfaceNavy,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bidding Started', style: TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(tender.biddingStart),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bidding Ends', style: TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(tender.softEnd),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
              if (isRound1Live || isRound2Live) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.logiqGreenBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.logiqGreenBorder),
                  ),
                  child: Column(
                    children: [
                      const Text('TIME LEFT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.logiqGreen)),
                      Text(countdown, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.logiqGreenDark)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveLeaderboardCard(Tender tender, Auction? auction, List<_RankRow> rankings) {
    final now = DateTime.now();
    final isRound1Ended = auction?.status == AuctionStatus.stage1Completed ||
        (auction?.status == AuctionStatus.stage1Live && (auction != null && now.isAfter(auction.stage1End)));
    final isRound2Live = auction?.status == AuctionStatus.stage2Live;

    final hasBids = rankings.isNotEmpty;
    final lowest = hasBids ? rankings.first.amount : null;
    final savings = hasBids ? (tender.ceilingBid - lowest!).clamp(0.0, double.infinity) : 0.0;
    final savingsPct = hasBids && tender.ceilingBid > 0 ? (savings / tender.ceilingBid * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.leaderboard_outlined, size: 18, color: AppColors.logiqGreen),
                  SizedBox(width: 8),
                  Text(
                    'Live Carrier Bids & Ranks (L1–L5)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.surfaceNavy,
                    ),
                  ),
                ],
              ),
              if (hasBids)
                Text(
                  'Saved ₹${savings.toInt()} (${savingsPct.toStringAsFixed(1)}%)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.logiqGreen,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasBids)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceCanvas,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                children: [
                  Icon(Icons.hourglass_empty_rounded, size: 24, color: AppColors.inkSoft),
                  SizedBox(height: 6),
                  Text('No carrier bids yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                  Text('Invited carriers are actively monitoring this tender.', style: TextStyle(fontSize: 11, color: AppColors.inkFaint)),
                ],
              ),
            )
          else
            Column(
              children: List.generate(rankings.length, (index) {
                final r = rankings[index];
                final isL1 = index == 0;
                final diff = r.amount - rankings.first.amount;
                final displayName = isRound2Live ? 'Bidder ${index + 1}' : r.name;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isL1 ? AppColors.logiqGreenBg : AppColors.surfaceCanvas,
                    borderRadius: BorderRadius.circular(8),
                    border: isL1 ? Border.all(color: AppColors.logiqGreenBorder) : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isL1 ? AppColors.logiqGreen : AppColors.outline,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'L${r.rank}',
                          style: TextStyle(
                            color: isL1 ? Colors.white : AppColors.inkSoft,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isL1 ? FontWeight.w700 : FontWeight.w500,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatCurrency(r.amount),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isL1 ? AppColors.logiqGreenDark : AppColors.ink,
                            ),
                          ),
                          if (!isL1)
                            Text(
                              '+${_formatCurrency(diff)}',
                              style: const TextStyle(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
          if (isRound1Ended) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade800, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Stage 1 ended. Top qualifying carriers (L1–L5) are ready for Stage 2.',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade900, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final auth = context.read<AuthProvider>();
                        final userId = auth.currentUser?.id;
                        if (userId == null) return;
                        final success = await context.read<TenderProvider>().startRound2BlindAuction(
                          tenderId: tender.id!,
                          userId: userId,
                        );
                        if (success && mounted) {
                          messenger.showSnackBar(
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
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.visibility_off, size: 16),
                      label: const Text('Start Stage 2 Blind Auction', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCarrierInvitesCard(Tender tender, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.hub_rounded, size: 20, color: AppColors.secondary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Carriers Participating',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.surfaceNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count verified carriers invited',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.emeraldSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'APPROVED ONLY',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppColors.emeraldSuccess,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceToggleCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.verified_rounded, size: 20, color: AppColors.emeraldSuccess),
              SizedBox(width: 10),
              Text(
                'E-Way & GST Verified',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.surfaceNavy,
                ),
              ),
            ],
          ),
          Switch.adaptive(
            value: _isGstVerified,
            activeTrackColor: AppColors.emeraldSuccess,
            onChanged: (val) {
              setState(() => _isGstVerified = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar(BuildContext context, Tender tender, Auction? auction) {
    final now = DateTime.now();
    final isRound1Live = auction?.status == AuctionStatus.stage1Live && (auction != null && !now.isAfter(auction.stage1End));
    final isRound1Ended = auction?.status == AuctionStatus.stage1Completed ||
        (auction?.status == AuctionStatus.stage1Live && (auction != null && now.isAfter(auction.stage1End)));
    final isRound2Live = auction?.status == AuctionStatus.stage2Live;
    final isCompleted = auction?.status == AuctionStatus.completed || tender.status == TenderStatus.completed;

    String durationText = 'Live';
    if (auction != null) {
      if (isRound1Live) {
        final rem = auction.stage1End.difference(now);
        final m = rem.inMinutes;
        final s = rem.inSeconds % 60;
        durationText = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} left';
      } else if (isRound2Live) {
        final rem = auction.stage2End.difference(now);
        final m = rem.inMinutes;
        final s = rem.inSeconds % 60;
        durationText = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} left';
      } else if (isRound1Ended) {
        durationText = 'Stage 1 Ended';
      } else if (isCompleted) {
        durationText = 'Completed';
      }
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'AUCTION TIMING',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    durationText,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.surfaceNavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: isRound1Ended
                      ? ElevatedButton.icon(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final auth = context.read<AuthProvider>();
                            final userId = auth.currentUser?.id;
                            if (userId == null) return;
                            final success = await context.read<TenderProvider>().startRound2BlindAuction(
                              tenderId: tender.id!,
                              userId: userId,
                            );
                            if (success && mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Stage 2 Blind Auction is now LIVE!'),
                                  backgroundColor: AppColors.logiqGreen,
                                ),
                              );
                              await _loadData();
                            }
                          },
                          icon: const Icon(Icons.visibility_off, size: 18, color: Colors.white),
                          label: const Text(
                            'START ROUND 2 BLIND AUCTION',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.logiqGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        )
                      : isRound2Live
                          ? Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.deepPurple.shade200),
                              ),
                              child: Text(
                                'ROUND 2 BLIND AUCTION LIVE',
                                style: TextStyle(
                                  color: Colors.deepPurple.shade800,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            )
                          : isCompleted
                              ? Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.logiqGreenBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.logiqGreenBorder),
                                  ),
                                  child: const Text(
                                    'AUCTION COMPLETED',
                                    style: TextStyle(
                                      color: AppColors.logiqGreenDark,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                )
                              : Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.logiqGreenBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.logiqGreenBorder),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.logiqGreen,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'LIVE REVERSE AUCTION ACTIVE',
                                        style: TextStyle(
                                          color: AppColors.logiqGreenDark,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
