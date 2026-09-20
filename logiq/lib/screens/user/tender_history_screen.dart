import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/providers/tender_provider.dart';
import 'package:logiq/models/tender.dart';
import 'package:logiq/services/auction_service.dart';

class TenderHistoryScreen extends StatefulWidget {
  const TenderHistoryScreen({super.key});

  @override
  State<TenderHistoryScreen> createState() => _TenderHistoryScreenState();
}

class _TenderHistoryScreenState extends State<TenderHistoryScreen> {
  final _auctionService = AuctionService.instance;
  final Map<int, _WinnerInfo> _winnerCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().currentUser;
    final tenderProvider = context.read<TenderProvider>();
    await tenderProvider.loadTendersForUser(user!.id!);
    if (!mounted) return;

    for (final t in tenderProvider.completedTenders) {
      if (t.id != null && !_winnerCache.containsKey(t.id)) {
        final result = await _auctionService.getResultByTender(t.id!);
        if (result != null && mounted) {
          setState(() {
            _winnerCache[t.id!] = _WinnerInfo(
              name: result.winnerName,
              bid: result.winningBid,
              completedAt: result.completedAt,
            );
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenders = context.watch<TenderProvider>();
    final completed = tenders.completedTenders;

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
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
                  Text('Tender History', style: AppTextStyles.h2),
                ],
              ),
            ),
            Expanded(
              child: tenders.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.logiqGreen))
                  : completed.isEmpty
                      ? _emptyState()
                      : RefreshIndicator(
                          color: AppColors.logiqGreen,
                          onRefresh: _loadData,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: completed.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final tender = completed[index];
                              return _HistoryCard(
                                tender: tender,
                                winner: _winnerCache[tender.id],
                                onTap: () => context.push('/tender/${tender.id}'),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.logiqGreenBg, shape: BoxShape.circle),
              child: const Icon(Icons.history_rounded, size: 36, color: AppColors.logiqGreen),
            ),
            const SizedBox(height: 20),
            const Text('No Completed Tenders', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Tenders will appear here once the reverse auction is completed.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted.copyWith(color: AppColors.inkFaint),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Tender tender;
  final _WinnerInfo? winner;
  final VoidCallback onTap;

  const _HistoryCard({required this.tender, this.winner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(tender.title, style: AppTextStyles.h3, maxLines: 1, overflow: TextOverflow.ellipsis)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.logiqGreenBg, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Completed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.logiqGreen)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.route_rounded, size: 16, color: AppColors.inkSoft),
                const SizedBox(width: 6),
                Expanded(child: Text(tender.shortRoute, style: AppTextStyles.body.copyWith(color: AppColors.inkSoft))),
              ],
            ),
            if (winner != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.logiqGreenBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, size: 20, color: AppColors.logiqGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Winner: ${winner!.name}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.logiqGreen)),
                          const SizedBox(height: 2),
                          Text('Final bid: ₹${_formatAmount(winner!.bid)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.logiqGreenDark)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.logiqGreen, size: 20),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    final str = amount.toInt().toString();
    if (str.length <= 3) return str;
    final chars = str.split('');
    final buf = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      final fromEnd = chars.length - i;
      if (fromEnd == 3 && i > 0) {
        buf.write(',');
      } else if (fromEnd > 3 && fromEnd.isOdd && i > 0) {
        buf.write(',');
      }
      buf.write(chars[i]);
    }
    return buf.toString();
  }
}

class _WinnerInfo {
  final String name;
  final double bid;
  final DateTime completedAt;
  const _WinnerInfo({required this.name, required this.bid, required this.completedAt});
}
