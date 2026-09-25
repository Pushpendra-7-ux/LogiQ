import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/core/widgets/empty_state.dart';
import 'package:logiq/core/widgets/tender_card.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/providers/tender_provider.dart';

import 'package:logiq/services/auth_service.dart';

class AvailableTendersScreen extends StatefulWidget {
  const AvailableTendersScreen({super.key});

  @override
  State<AvailableTendersScreen> createState() => _AvailableTendersScreenState();
}

class _AvailableTendersScreenState extends State<AvailableTendersScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      var tid = auth.currentTransporter?.id;
      if (tid == null && auth.currentUser != null) {
        final profile = await AuthService.instance.ensureTransporterProfile(auth.currentUser!);
        tid = profile?.id;
      }
      if (!mounted) return;
      if (tid != null) {
        context.read<TenderProvider>().loadTendersForTransporter(tid);
      } else {
        context.read<TenderProvider>().loadAllTenders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tenderProvider = context.watch<TenderProvider>();
    final authProvider = context.watch<AuthProvider>();
    final tenders = tenderProvider.activeTenders.where((t) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return t.title.toLowerCase().contains(query) ||
          t.pickup.toLowerCase().contains(query) ||
          t.drop.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Available Tenders', style: AppTextStyles.h2),
        backgroundColor: AppColors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by city or title...',
                prefixIcon: const Icon(Icons.search, color: AppColors.inkSoft),
                filled: true,
                fillColor: AppColors.surfaceAlt,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: tenderProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.electricBlue))
          : tenders.isEmpty
              ? const EmptyState(
                  icon: Icons.local_shipping_outlined,
                  title: 'No Available Tenders',
                  subtitle: 'There are no active tenders matching your criteria.',
                )
              : RefreshIndicator(
                  color: AppColors.electricBlue,
                  onRefresh: () async {
                    var tid = authProvider.currentTransporter?.id;
                    if (tid == null && authProvider.currentUser != null) {
                      final profile = await AuthService.instance.ensureTransporterProfile(authProvider.currentUser!);
                      tid = profile?.id;
                    }
                    if (tid != null) {
                      await tenderProvider.loadTendersForTransporter(tid);
                    } else {
                      await tenderProvider.loadAllTenders();
                    }
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: tenders.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final tender = tenders[index];
                      return TenderCard(
                        tender: tender,
                        animationIndex: index,
                        onTap: () => context.push('/tender/${tender.id}'),
                      );
                    },
                  ),
                ),
    );
  }
}
