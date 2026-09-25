import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/core/utils/haptics.dart';
import 'package:logiq/core/widgets/big_button.dart';
import 'package:logiq/core/widgets/bid_amount_input.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/providers/tender_provider.dart';
import 'package:logiq/providers/auction_provider.dart';
import 'package:logiq/providers/bid_provider.dart';
import 'package:logiq/services/tender_service.dart';
import 'package:logiq/services/auth_service.dart';
import 'package:intl/intl.dart';

class PlaceBidScreen extends StatefulWidget {
  final int tenderId;

  const PlaceBidScreen({super.key, required this.tenderId});

  @override
  State<PlaceBidScreen> createState() => _PlaceBidScreenState();
}

class _PlaceBidScreenState extends State<PlaceBidScreen> {
  double _currentAmount = 0;
  bool _isSubmitting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auctionProv = context.read<AuctionProvider>();
      final tenderProv = context.read<TenderProvider>();
      await auctionProv.loadAuction(widget.tenderId);
      if (!mounted) return;
      var tender = tenderProv.tenderById(widget.tenderId);
      tender ??= auctionProv.currentTender;
      tender ??= await TenderService.instance.getTenderById(widget.tenderId);
      final t = tender;
      if (t != null && _currentAmount == 0) {
        final step = t.priceDifference;
        if (auctionProv.rankings.isNotEmpty) {
          final lowest = auctionProv.rankings.first.amount;
          setState(() => _currentAmount = (lowest - step).clamp(100.0, t.ceilingBid));
        } else {
          setState(() => _currentAmount = (t.ceilingBid - step).clamp(100.0, t.ceilingBid));
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimer(DateTime? endTime) {
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
    final m = diff.inMinutes.toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  void _submitBid() async {
    final messenger = ScaffoldMessenger.of(context);
    final tenderProv = context.read<TenderProvider>();
    final auctionProv = context.read<AuctionProvider>();
    final auth = context.read<AuthProvider>();

    var tender = tenderProv.tenderById(widget.tenderId);
    tender ??= auctionProv.currentTender;
    tender ??= await TenderService.instance.getTenderById(widget.tenderId);
    if (tender == null) {
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Tender details not available.'),
        ),
      );
      return;
    }

    final now = DateTime.now();
    if (now.isBefore(tender.biddingStart)) {
      Haptics.error();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Bidding has not started yet. Starts on ${DateFormat("dd MMM, hh:mm a").format(tender.biddingStart)}'),
        ),
      );
      return;
    }

    final effectiveEnd = auctionProv.currentAuction?.stage1End ?? tender.softEnd;
    if (now.isAfter(effectiveEnd)) {
      Haptics.error();
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Round 1 bidding time has expired.'),
        ),
      );
      return;
    }

    if (_currentAmount <= 0) {
      final lowest = auctionProv.rankings.isNotEmpty ? auctionProv.rankings.first.amount : tender.ceilingBid;
      _currentAmount = (lowest - tender.priceDifference).clamp(100.0, tender.ceilingBid);
    }

    if (_currentAmount > tender.ceilingBid) {
      Haptics.error();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Bid cannot exceed the cap price of ₹${tender.ceilingBid.toStringAsFixed(0)}'),
        ),
      );
      return;
    }

    var transporterId = auth.currentTransporter?.id;
    if (transporterId == null && auth.currentUser != null) {
      final profile = await AuthService.instance.ensureTransporterProfile(auth.currentUser!);
      transporterId = profile?.id;
    }
    transporterId ??= auth.currentUser?.id ?? 1;

    final myPrev = auctionProv.rankings.where((r) => r.transporterId == transporterId).firstOrNull;
    if (myPrev != null && _currentAmount >= myPrev.amount) {
      Haptics.error();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Your new bid must be lower than your previous bid of ₹${myPrev.amount.toStringAsFixed(0)}'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await auctionProv.placeBid(
      transporterId,
      _currentAmount,
      1,
      tenderId: widget.tenderId,
    );
    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      Haptics.bidSubmitted();
      await Future.wait([
        tenderProv.loadAllTenders(),
        context.read<BidProvider>().loadBidsForTransporter(transporterId),
        auctionProv.loadAuction(widget.tenderId),
      ]);
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _SuccessDialog(),
      );
      
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      }
    } else {
      Haptics.error();
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Bid must be lower by at least the required price difference.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenderProv = context.watch<TenderProvider>();
    final auctionProv = context.watch<AuctionProvider>();
    final tender = tenderProv.tenderById(widget.tenderId) ?? auctionProv.currentTender;
    
    if (tender == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.logiqGreen)),
      );
    }

    final hasLowest = auctionProv.rankings.isNotEmpty;
    final lowestBid = hasLowest ? auctionProv.rankings.first.amount : null;
    final maxAllowedBid = hasLowest ? lowestBid! - tender.priceDifference : tender.ceilingBid;
    final now = DateTime.now();
    final isBeforeStart = now.isBefore(tender.biddingStart);
    final effectiveEnd = auctionProv.currentAuction?.stage1End ?? tender.softEnd;

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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Place Your Bid', style: AppTextStyles.h3),
          backgroundColor: AppColors.background,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isBeforeStart ? Colors.blue.shade50 : AppColors.logiqGreenBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isBeforeStart ? Colors.blue.shade200 : AppColors.logiqGreenBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isBeforeStart ? Icons.schedule : Icons.timer_outlined,
                        size: 14,
                        color: isBeforeStart ? Colors.blue.shade800 : AppColors.logiqGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isBeforeStart
                            ? 'Starts ${_formatTimer(tender.biddingStart)}'
                            : _formatTimer(effectiveEnd),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isBeforeStart ? Colors.blue.shade900 : AppColors.logiqGreen,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isBeforeStart)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.blue.shade800, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Auction is scheduled. Bidding opens on ${DateFormat("dd MMM, hh:mm a").format(tender.biddingStart)} and closes on ${DateFormat("dd MMM, hh:mm a").format(effectiveEnd)}.',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.blue.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your bid is private — others can\'t see it',
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tender.title, style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  Text(tender.route, style: AppTextStyles.bodyMuted),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCanvas,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cap Price', style: AppTextStyles.caption.copyWith(color: AppColors.inkSoft)),
                              const SizedBox(height: 2),
                              Text('₹${tender.ceilingBid.toInt()}', style: AppTextStyles.bodyStrong),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.logiqGreenBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Current L1', style: AppTextStyles.caption.copyWith(color: AppColors.logiqGreen)),
                              const SizedBox(height: 2),
                              Text(
                                hasLowest ? '₹${lowestBid!.toInt()}' : 'No bids yet',
                                style: AppTextStyles.bodyStrong.copyWith(color: AppColors.logiqGreen),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCanvas,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Min Decrement', style: AppTextStyles.caption.copyWith(color: AppColors.inkSoft)),
                              const SizedBox(height: 2),
                              Text('₹${tender.priceDifference.toInt()}', style: AppTextStyles.bodyStrong),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Enter Bid Amount', style: AppTextStyles.h3, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              hasLowest
                  ? 'To be L1, enter ₹${maxAllowedBid.toInt()} or lower'
                  : 'Enter ₹${tender.ceilingBid.toInt()} or lower',
              style: AppTextStyles.bodyMuted.copyWith(color: AppColors.logiqGreen, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            BidAmountInput(
              currentAmount: _currentAmount,
              minDecrement: tender.priceDifference,
              onAmountChanged: (val) {
                setState(() => _currentAmount = val);
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [500, 1000, 2000, 5000].map((step) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ActionChip(
                    label: Text('-₹$step', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.ink)),
                    onPressed: () {
                      final newAmt = (_currentAmount - step).clamp(100.0, tender.ceilingBid);
                      setState(() => _currentAmount = newAmt);
                    },
                    backgroundColor: AppColors.surfaceCanvas,
                    side: const BorderSide(color: AppColors.outline),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BigButton(
            label: isBeforeStart
                ? 'BIDDING NOT STARTED YET'
                : (now.isAfter(effectiveEnd) ? 'ROUND 1 BIDDING CLOSED' : 'SUBMIT BID'),
            icon: isBeforeStart ? Icons.schedule : Icons.check_circle,
            onPressed: (_isSubmitting || isBeforeStart || now.isAfter(effectiveEnd)) ? null : _submitBid,
            color: (isBeforeStart || now.isAfter(effectiveEnd)) ? AppColors.inkSoft : AppColors.primary,
            isLoading: _isSubmitting,
          ),
        ),
      ),
    ),
  );
}
}

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80)
                .animate()
                .scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            const Text('Bid Submitted!', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            const Text(
              'Your bid has been recorded successfully.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
