import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/core/widgets/empty_state.dart';
import 'package:logiq/core/widgets/status_chip.dart';
import 'package:logiq/models/tender.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/providers/tender_provider.dart';

class ActiveAuctionsScreen extends StatefulWidget {
  const ActiveAuctionsScreen({super.key});

  @override
  State<ActiveAuctionsScreen> createState() => _ActiveAuctionsScreenState();
}

class _ActiveAuctionsScreenState extends State<ActiveAuctionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tid = context.read<AuthProvider>().currentTransporter?.id;
      if (tid != null) {
        context.read<TenderProvider>().loadTendersForTransporter(tid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tenderProvider = context.watch<TenderProvider>();
    final liveTenders = tenderProvider.tenders.where((t) =>
        t.status == TenderStatus.stage1 || t.status == TenderStatus.stage2).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Live Auctions', style: AppTextStyles.h2),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: tenderProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.electricBlue))
          : liveTenders.isEmpty
              ? const EmptyState(
                  icon: Icons.gavel_rounded,
                  title: 'No Live Auctions',
                  subtitle: 'There are no live reverse auctions running right now.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: liveTenders.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final tender = liveTenders[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.electricBlue, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.electricBlue.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  tender.title,
                                  style: AppTextStyles.h3,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              StatusChip(
                                label: tender.status.label,
                                color: AppColors.danger,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(tender.route, style: AppTextStyles.bodyMuted),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navy,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () {
                                if (tender.status == TenderStatus.stage2) {
                                  context.push('/tender/${tender.id}/live');
                                } else {
                                  context.push('/tender/${tender.id}/bid');
                                }
                              },
                              icon: const Icon(Icons.flash_on, size: 20),
                              label: Text(
                                tender.status == TenderStatus.stage2
                                    ? 'ENTER LIVE AUCTION'
                                    : 'SUBMIT STAGE 1 BID',
                                style: AppTextStyles.button,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
