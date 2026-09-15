import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/tender_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/tender/tender_card.dart';
import '../../core/theme/app_colors.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});
  @override State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TenderProvider>().fetchTenders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TenderProvider>();
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${user?.name ?? "User"}'),
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
        onRefresh: () => tp.fetchTenders(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 3 Primary Action Cards
            _ActionCard(
              title: 'CREATE TENDER',
              subtitle: 'Create a new transport requirement',
              icon: Icons.add_circle_outline,
              color: AppColors.primary,
              onTap: () => context.push('/user/create-tender'),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              title: 'DRAFT TENDERS',
              subtitle: 'Continue unfinished requirements',
              icon: Icons.edit_note,
              color: AppColors.warning,
              onTap: () => context.push('/user/drafts'),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              title: 'TENDER HISTORY',
              subtitle: 'Completed tenders and winning bids',
              icon: Icons.history,
              color: AppColors.accent,
              onTap: () => context.push('/user/history'),
            ),
            const SizedBox(height: 24),
            const Text('Active Tenders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (tp.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (tp.tenders.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No active tenders found. Tap "CREATE TENDER" to begin.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
                ),
              )
            else
              ...tp.tenders.map((t) => TenderCard(
                    tender: t,
                    onTap: () {
                      if (t.status.contains('LIVE')) {
                        context.push('/user/tender/${t.id}/monitor');
                      } else {
                        context.push('/user/tender/${t.id}/review');
                      }
                    },
                  )),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}