import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/providers/tender_provider.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user?.id != null) {
      await context.read<TenderProvider>().loadTendersForUser(user!.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tenders = context.watch<TenderProvider>();

    final userName = auth.currentUser?.name ?? 'User';
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    final draftCount = tenders.draftTenders.length;
    final activeCount = tenders.activeTenders.length;
    final historyCount = tenders.completedTenders.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(userName, initial),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.logiqGreen,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dashboard',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                      const SizedBox(height: 4),
                      const Text('Manage tenders and real-time carrier bids', style: AppTextStyles.bodyMuted),
                      const SizedBox(height: 24),
                      _CreateTenderHero(onTap: () => context.go('/tender/create')),
                      const SizedBox(height: 16),
                      _DashboardCard(
                        icon: Icons.mail_outline,
                        title: 'Draft Tenders',
                        subtitle: '$draftCount drafts saved',
                        onTap: () => context.push('/drafts'),
                      ),
                      const SizedBox(height: 16),
                      _DashboardCard(
                        icon: Icons.cell_tower,
                        title: 'Active Tenders',
                        subtitle: 'Live reverse auction bids',
                        badge: '$activeCount Live',
                        onTap: () => context.go('/active-tenders'),
                      ),
                      const SizedBox(height: 16),
                      _DashboardCard(
                        icon: Icons.history,
                        title: 'Tender History',
                        subtitle: 'Archived contracts & fulfillment',
                        badge: '$historyCount completed',
                        onTap: () => context.go('/tender/history'),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(String userName, String initial) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: AppColors.logiqGreen, shape: BoxShape.circle),
                child: const Icon(Icons.local_shipping, color: AppColors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Text('LogiQ', style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          InkWell(
            onTap: () => context.push('/profile'),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  Text('Hi, $userName', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(color: AppColors.logiqGreenBg, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        initial,
                        style: AppTextStyles.body.copyWith(color: AppColors.logiqGreen, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateTenderHero extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateTenderHero({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.logiqGreen, AppColors.logiqGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.logiqGreen.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: AppColors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create Tender',
                        style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'New auction or freight order',
                        style: TextStyle(color: AppColors.white.withValues(alpha: 0.8), fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const CircleAvatar(
                  backgroundColor: AppColors.white,
                  radius: 20,
                  child: Icon(Icons.arrow_forward, color: AppColors.logiqGreen, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(color: AppColors.logiqGreenBg, shape: BoxShape.circle),
                  child: Icon(icon, color: AppColors.logiqGreen),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.ink),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.logiqGreenBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                badge!,
                                style: const TextStyle(color: AppColors.logiqGreen, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: AppTextStyles.bodyMuted),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.inkSoft),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
