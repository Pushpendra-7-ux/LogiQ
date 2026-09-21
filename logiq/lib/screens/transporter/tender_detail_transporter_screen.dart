import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/core/utils/formatters.dart';
import 'package:logiq/core/widgets/big_button.dart';
import 'package:logiq/core/widgets/route_display.dart';
import 'package:logiq/core/widgets/status_chip.dart';
import 'package:logiq/providers/tender_provider.dart';
import 'package:logiq/providers/auction_provider.dart';
import 'package:logiq/models/tender.dart';
import 'package:logiq/models/material.dart';

class TenderDetailTransporterScreen extends StatefulWidget {
  final int tenderId;

  const TenderDetailTransporterScreen({super.key, required this.tenderId});

  @override
  State<TenderDetailTransporterScreen> createState() => _TenderDetailTransporterScreenState();
}

class _TenderDetailTransporterScreenState extends State<TenderDetailTransporterScreen> {
  List<MaterialItem> materials = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final tenderProvider = context.read<TenderProvider>();
    final auctionProvider = context.read<AuctionProvider>();
    
    final results = await Future.wait([
      tenderProvider.materialsFor(widget.tenderId),
      auctionProvider.loadAuction(widget.tenderId),
      tenderProvider.getOrFetchTender(widget.tenderId),
    ]);
    
    if (mounted) {
      setState(() {
        materials = results[0] as List<MaterialItem>;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenderProvider = context.watch<TenderProvider>();
    final auctionProvider = context.watch<AuctionProvider>();
    final tender = tenderProvider.tenderById(widget.tenderId);
    
    if (isLoading && tender == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.electricBlue)),
      );
    }

    if (tender == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tender Not Found')),
        body: const Center(child: Text('Tender not found or unavailable.')),
      );
    }

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
          title: Text(tender.title, style: AppTextStyles.h3),
          backgroundColor: AppColors.background,
          elevation: 0,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusChip(
                      label: tender.status.label,
                      color: _getStatusColor(tender.status),
                      icon: _getStatusIcon(tender.status),
                    ),
                    const SizedBox(height: 16),
                    RouteDisplay(
                      pickup: tender.pickup,
                      drop: tender.drop,
                      compact: false,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Material Information'),
                    _buildMaterialCard(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Schedule'),
                    _buildDateCard(tender),
                    const SizedBox(height: 24),
                    if (tender.priceDifference > 0) ...[
                      _buildSectionTitle('Bidding Rules'),
                      _buildInfoCard(
                        'Minimum Bid Difference',
                        '₹${tender.priceDifference.toStringAsFixed(0)}',
                        Icons.rule,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
        bottomNavigationBar: _buildBottomAction(tender, auctionProvider),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: AppTextStyles.h4),
    );
  }

  Widget _buildMaterialCard() {
    if (materials.isEmpty) return const Text('No material information available.');
    final item = materials.first;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.description, style: AppTextStyles.bodyLarge),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quantity: ${item.quantity} ${item.unit}', style: AppTextStyles.bodyMedium),
              if (item.remarks.isNotEmpty)
                Text('HSN: ${item.remarks}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(Tender tender) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery Window', style: AppTextStyles.label),
                    Text(Formatters.dateRange(tender.deliveryStart, tender.deliveryEnd), style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.timer, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bidding Starts', style: AppTextStyles.label),
                    Text(Formatters.formatDate(tender.biddingStart), style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.label.copyWith(color: Colors.blue.shade900)),
                Text(value, style: AppTextStyles.h4.copyWith(color: Colors.blue.shade900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomAction(Tender tender, AuctionProvider auction) {
    if (tender.status == TenderStatus.completed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: BigButton(
          label: 'VIEW RESULTS',
          icon: Icons.emoji_events,
          color: AppColors.textPrimary,
          onPressed: () => context.push('/tender/${tender.id}/result'),
        ),
      );
    }
    
    if (tender.status == TenderStatus.stage2) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: BigButton(
          label: 'JOIN LIVE AUCTION',
          icon: Icons.play_circle_fill,
          color: AppColors.primary,
          onPressed: () => context.push('/tender/${tender.id}/live'),
        ),
      );
    }

    if (tender.status == TenderStatus.scheduled || tender.status == TenderStatus.stage1) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: BigButton(
          label: 'PLACE BID',
          icon: Icons.gavel,
          color: AppColors.primary,
          onPressed: () => context.push('/tender/${tender.id}/bid'),
        ),
      );
    }

    return null;
  }

  Color _getStatusColor(TenderStatus status) {
    switch (status) {
      case TenderStatus.stage1:
      case TenderStatus.stage2:
        return AppColors.primary;
      case TenderStatus.completed:
        return Colors.green;
      case TenderStatus.cancelled:
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(TenderStatus status) {
    switch (status) {
      case TenderStatus.stage1:
      case TenderStatus.stage2:
        return Icons.gavel;
      case TenderStatus.completed:
        return Icons.check_circle;
      case TenderStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }
}
