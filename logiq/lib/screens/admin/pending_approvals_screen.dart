import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../core/theme/app_colors.dart';

class PendingApprovalsScreen extends StatefulWidget {
  const PendingApprovalsScreen({super.key});
  @override State<PendingApprovalsScreen> createState() => _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState extends State<PendingApprovalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchPending();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final users = admin.pendingUsers;
    final transporters = admin.pendingTransporters;

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Approvals')),
      body: admin.isLoading
          ? const Center(child: CircularProgressIndicator())
          : (users.isEmpty && transporters.isEmpty)
              ? const Center(child: Text('No pending accounts.', style: TextStyle(fontSize: 16, color: Colors.grey)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (users.isNotEmpty) ...[
                      const Text('Tender Makers (Users)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      const SizedBox(height: 8),
                      ...users.map((u) => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Email: ${u['email']}', style: const TextStyle(color: Colors.grey)),
                                  if (u['phone'] != null) Text('Phone: ${u['phone']}', style: const TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () => admin.rejectUser(u['id']),
                                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                                        child: const Text('REJECT'),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        onPressed: () => admin.approveUser(u['id']),
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                        child: const Text('APPROVE'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],
                    if (transporters.isNotEmpty) ...[
                      const Text('Transporters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accent)),
                      const SizedBox(height: 8),
                      ...transporters.map((t) => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t['company_name'] ?? t['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Email: ${t['email']}', style: const TextStyle(color: Colors.grey)),
                                  Text('GSTIN: ${t['gst_number'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('Transport ID: ${t['transport_id'] ?? 'N/A'}', style: const TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () => admin.rejectUser(t['id']),
                                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                                        child: const Text('REJECT'),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        onPressed: () => admin.approveUser(t['id']),
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                        child: const Text('APPROVE'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ],
                ),
    );
  }
}