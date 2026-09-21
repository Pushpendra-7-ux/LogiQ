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

class PlaceBidScreen extends StatefulWidget {
  final int tenderId;

  const PlaceBidScreen({super.key, required this.tenderId});

  @override
  State<PlaceBidScreen> createState() => _PlaceBidScreenState();
}

class _PlaceBidScreenState extends State<PlaceBidScreen> {
  double _currentAmount = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auctionProv = context.read<AuctionProvider>();
      final tenderProv = context.read<TenderProvider>();
      await auctionProv.loadAuction(widget.tenderId);
      if (!mounted) return;
      final tender = tenderProv.tenderById(widget.tenderId);
      if (tender != null && _currentAmount == 0) {
        final step = tender.priceDifference;
        if (auctionProv.rankings.isNotEmpty) {
          final lowest = auctionProv.rankings.first.amount;
          setState(() => _currentAmount = (lowest - step).clamp(100.0, tender.ceilingBid));
        } else {
          setState(() => _currentAmount = (tender.ceilingBid - step).clamp(100.0, tender.ceilingBid));
        }
      }
    });
  }

  void _submitBid() async {
    final tender = context.read<TenderProvider>().tenderById(widget.tenderId);
    if (tender == null || _currentAmount <= 0) return;

    if (_currentAmount > tender.ceilingBid) {
      Haptics.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Bid cannot exceed the cap price of ₹${tender.ceilingBid.toStringAsFixed(0)}'),
        ),
      );
      return;
    }

    final auctionProv = context.read<AuctionProvider>();
    final step = tender.priceDifference;
    if (auctionProv.rankings.isNotEmpty) {
      final lowestBid = auctionProv.rankings.first.amount;
      if (_currentAmount > lowestBid - step + 0.001) {
        Haptics.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('To be L1, bid must be at least ₹${step.toStringAsFixed(0)} lower than current lowest bid (₹${lowestBid.toStringAsFixed(0)})'),
          ),
        );
        return;
      }
    }

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Confirm Enforceable Bid', style: AppTextStyles.h2.copyWith(color: AppColors.navy)),
              const SizedBox(height: 8),
              Text(
                'You are submitting a legally binding offer of ₹${_currentAmount.toStringAsFixed(0)}. This cannot be undone.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 24),
              BigButton(
                label: 'SUBMIT ₹${_currentAmount.toStringAsFixed(0)} BID',
                color: AppColors.navy,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
              const SizedBox(height: 12),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancel', style: AppTextStyles.bodyMuted),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();
    final transporterId = auth.currentTransporter?.id;
    if (transporterId == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    final success = await context.read<AuctionProvider>().placeBid(transporterId, _currentAmount, 1);
    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      Haptics.bidSubmitted();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _SuccessDialog(),
      );
      
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
        context.pop();
      }
    } else {
      Haptics.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Bid must be lower by at least the required price difference.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tender = context.watch<TenderProvider>().tenderById(widget.tenderId);
    final auctionProv = context.watch<AuctionProvider>();
    
    if (tender == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Tender not found')),
      );
    }

    final hasLowest = auctionProv.rankings.isNotEmpty;
    final lowestBid = hasLowest ? auctionProv.rankings.first.amount : null;
    final maxAllowedBid = hasLowest ? lowestBid! - tender.priceDifference : tender.ceilingBid;

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
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BigButton(
            label: 'SUBMIT BID',
            icon: Icons.check_circle,
            onPressed: _currentAmount > 0 && !_isSubmitting ? _submitBid : null,
            color: AppColors.primary,
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
