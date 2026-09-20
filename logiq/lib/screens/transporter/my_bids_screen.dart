import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/core/utils/formatters.dart';
import 'package:logiq/core/widgets/price_display.dart';
import 'package:logiq/core/widgets/status_chip.dart';
import 'package:logiq/core/widgets/empty_state.dart';
import 'package:logiq/providers/bid_provider.dart';
import 'package:logiq/providers/tender_provider.dart';

class MyBidsScreen extends StatefulWidget {
  const MyBidsScreen({super.key});

  @override
  State<MyBidsScreen> createState() => _MyBidsScreenState();
}

class _MyBidsScreenState extends State<MyBidsScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final bidProvider = context.watch<BidProvider>();
    final tenderProvider = context.watch<TenderProvider>();
    final allBids = bidProvider.myBids;

    final filteredBids = allBids.where((bid) {
      if (_selectedFilter == 'All') return true;
      // Mock filtering logic, to be improved based on robust bid statuses
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Bids', style: AppTextStyles.h3),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: ['All', 'Active', 'Won', 'Lost'].map((filter) {
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filter, style: TextStyle(color: isSelected ? Colors.black : AppColors.textSecondary)),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: filteredBids.isEmpty
                ? EmptyState(
                    icon: Icons.gavel,
                    title: 'No bids yet',
                    subtitle: 'You haven\'t placed any bids. Check available tenders to get started.',
                    actionLabel: 'Browse Tenders',
                    onAction: () {},
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredBids.length,
                    itemBuilder: (context, index) {
                      final bid = filteredBids[index];
                      final tender = tenderProvider.tenderById(bid.tenderId);
                      
                      if (tender == null) return const SizedBox.shrink();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(tender.title, style: AppTextStyles.h4, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                  StatusChip(
                                    label: 'Stage ${bid.stage}',
                                    color: AppColors.primary,
                                    icon: Icons.layers,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(tender.route, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Your Bid', style: AppTextStyles.label),
                                      PriceDisplay(amount: bid.amount, style: AppTextStyles.h3),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Submitted', style: AppTextStyles.label),
                                      Text(Formatters.formatDate(bid.submittedAt), style: AppTextStyles.bodyMedium),
                                    ],
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
