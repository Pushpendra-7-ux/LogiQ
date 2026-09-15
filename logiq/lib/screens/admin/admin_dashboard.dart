import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchDashboard();
      context.read<AdminProvider>().fetchPending();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final stats = admin.stats;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.go('/auth/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await admin.fetchDashboard();
          await admin.fetchPending();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Pending alert banner
            InkWell(
              onTap: () => context.push('/admin/pending'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.warning),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notification_important, color: AppColors.warning, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pending Approvals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('${admin.pendingUsers.length + admin.pendingTransporters.length} accounts awaiting approval', style: const TextStyle(color: Colors.black87)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('System Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _StatCard(title: 'Tender Makers', count: '${stats['total_users'] ?? 0}', icon: Icons.people, color: AppColors.primary),
                _StatCard(title: 'Transporters', count: '${stats['total_transporters'] ?? 0}', icon: Icons.local_shipping, color: AppColors.accent),
                _StatCard(title: 'Active Tenders', count: '${stats['active_tenders'] ?? 0}', icon: Icons.assignment, color: AppColors.liveGreen),
                _StatCard(title: 'Completed Auctions', count: '${stats['completed_auctions'] ?? 0}', icon: Icons.check_circle, color: AppColors.blindPurple),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.count, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(count, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}