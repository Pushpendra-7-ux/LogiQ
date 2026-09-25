import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/utils/haptics.dart';
import 'package:logiq/providers/tender_provider.dart';
import 'package:logiq/models/tender.dart';
import 'package:logiq/models/auction.dart';
import 'package:logiq/services/auction_service.dart';

class AdminTendersScreen extends StatefulWidget {
  final String? initialFilter;

  const AdminTendersScreen({super.key, this.initialFilter});

  @override
  State<AdminTendersScreen> createState() => _AdminTendersScreenState();
}

class _AdminTendersScreenState extends State<AdminTendersScreen> {
  String _filter = 'All';
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  Timer? _timer;
  final Map<int, Auction> _auctions = {};
  final AuctionService _auctionService = AuctionService.instance;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter ?? 'All';
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted) return;
      await _syncAuctions();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    await context.read<TenderProvider>().loadAllTenders();
    await _syncAuctions();
  }

  Future<void> _syncAuctions() async {
    final tenderProv = context.read<TenderProvider>();
    await tenderProv.loadAllTenders(silent: true);
    final active = tenderProv.activeTenders;
    for (final t in active) {
      if (t.id == null) continue;
      try {
        await _auctionService.checkAndTransitionAuction(t.id!);
        final auc = await _auctionService.getAuctionByTenderId(t.id!);
        if (auc != null) {
          _auctions[t.id!] = auc;
        }
      } catch (_) {}
    }
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
    final tenderProv = context.watch<TenderProvider>();
    
    List<Tender> filteredTenders = [];
    final all = tenderProv.allTenders;
    
    if (_filter == 'All') {
      filteredTenders = all;
    } else if (_filter == 'Active') {
      filteredTenders = tenderProv.activeTenders;
    } else if (_filter == 'Completed') {
      filteredTenders = tenderProv.completedTenders;
    } else if (_filter == 'Cancelled') {
      filteredTenders = all.where((t) => t.status == TenderStatus.cancelled).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'All Tenders',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    _buildFilterChip('All', all.length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Active', tenderProv.activeTenders.length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Completed', tenderProv.completedTenders.length),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Cancelled',
                      all.where((t) => t.status == TenderStatus.cancelled).length,
                    ),
                  ],
                ),
              ),
              Container(color: AppColors.outline, height: 1),
            ],
          ),
        ),
      ),
      body: tenderProv.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.logiqGreen))
          : RefreshIndicator(
              onRefresh: () => tenderProv.loadAllTenders(),
              color: AppColors.logiqGreen,
              child: filteredTenders.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text(
                            'No tenders found.',
                            style: TextStyle(fontSize: 14, color: AppColors.inkSoft),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: filteredTenders.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final tender = filteredTenders[index];
                        return _buildAdminTenderCard(context, tender);
                      },
                    ),
            ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _filter == label;
    return GestureDetector(
      onTap: () {
        setState(() => _filter = label);
        Haptics.selection();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : AppColors.surfaceCanvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.ink : AppColors.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.inkSoft,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.outline,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminTenderCard(BuildContext context, Tender tender) {
    final auction = _auctions[tender.id];
    final now = DateTime.now();
    final effectiveStage1Start = auction?.stage1Start ?? tender.biddingStart;
    final effectiveStage1End = auction?.stage1End ?? tender.softEnd;
    final effectiveStage2End = auction?.stage2End ?? tender.hardStop;
    final isScheduled = (auction?.status == AuctionStatus.scheduled || tender.status == TenderStatus.scheduled) && now.isBefore(effectiveStage1Start);
    final isPastStage1End = now.isAfter(effectiveStage1End);
    final isRound1Live = !isScheduled && (auction?.status == AuctionStatus.stage1Live || (auction == null && tender.status == TenderStatus.stage1)) && !isPastStage1End;
    final isRound1Ended = !isScheduled && ((auction?.status == AuctionStatus.stage1Completed) ||
        ((auction?.status == AuctionStatus.stage1Live || tender.status == TenderStatus.stage1) && isPastStage1End));
    final isRound2Live = auction?.status == AuctionStatus.stage2Live || tender.status == TenderStatus.stage2;
    final isCompleted = auction?.status == AuctionStatus.completed || tender.status == TenderStatus.completed;

    Color statusColor = AppColors.inkSoft;
    Color statusBg = AppColors.surfaceCanvas;
    String statusLabel = tender.status.label.toUpperCase();

    if (isScheduled) {
      statusColor = Colors.blue.shade800;
      statusBg = Colors.blue.shade50;
      statusLabel = 'SCHEDULED';
    } else if (isRound1Live) {
      statusColor = AppColors.logiqGreen;
      statusBg = AppColors.logiqGreenBg;
      statusLabel = 'STAGE 1 • LIVE';
    } else if (isRound2Live) {
      statusColor = Colors.deepPurple;
      statusBg = Colors.deepPurple.shade50;
      statusLabel = 'STAGE 2 • BLIND';
    } else if (isRound1Ended) {
      statusColor = Colors.orange.shade800;
      statusBg = Colors.orange.shade50;
      statusLabel = 'STAGE 1 COMPLETED';
    } else if (isCompleted) {
      statusColor = AppColors.logiqGreen;
      statusBg = AppColors.logiqGreenBg;
      statusLabel = 'COMPLETED';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Haptics.light();
            context.push('/tender/${tender.id}');
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tender.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isScheduled || isRound1Live || isRound2Live) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isScheduled ? Icons.schedule : Icons.timer_outlined, size: 12, color: AppColors.ink),
                            const SizedBox(width: 4),
                            Text(
                              isScheduled
                                  ? _formatTimeRemaining(effectiveStage1Start)
                                  : _formatTimeRemaining(isRound1Live ? effectiveStage1End : effectiveStage2End),
                              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCanvas,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.radio_button_checked, size: 14, color: AppColors.logiqGreen),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          tender.pickup,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward, size: 14, color: AppColors.inkSoft),
                      ),
                      const Icon(Icons.location_on, size: 14, color: AppColors.danger),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          tender.drop,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCanvas,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_shipping_outlined, size: 13, color: AppColors.inkSoft),
                              const SizedBox(width: 4),
                              Text(
                                tender.vehicleType,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Cap Price', style: TextStyle(fontSize: 10, color: AppColors.inkFaint)),
                        Text(
                          _currencyFormat.format(tender.ceilingBid),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
