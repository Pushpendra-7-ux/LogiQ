import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/tender_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_colors.dart';

class TransporterDashboard extends StatefulWidget {
  const TransporterDashboard({super.key});
  @override State<TransporterDashboard> createState() => _TransporterDashboardState();
}

class _TransporterDashboardState extends State<TransporterDashboard> {
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
        title: Text('${Formatters.greeting()}, ${user?.name ?? "Transporter"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/transporter/history'),
          ),
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
            Text('${tp.tenders.length} ACTIVE TENDERS', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            const SizedBox(height: 12),
            if (tp.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (tp.tenders.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('No active tenders available right now. Check back soon.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
                ),
              )
            else
              ...tp.tenders.map((t) => Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_shipping, size: 28, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(child: Text(t.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(Formatters.route(t.pickupLocation, t.dropLocation), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          const SizedBox(height: 8),
                          if (t.materials.isNotEmpty)
                            Text('${t.materials.first.quantity} ${t.materials.first.unit} ${t.materials.first.description}', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text(Formatters.dateRange(t.deliveryStart, t.deliveryEnd), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () => context.push('/transporter/tender/${t.id}'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text('VIEW TENDER →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}