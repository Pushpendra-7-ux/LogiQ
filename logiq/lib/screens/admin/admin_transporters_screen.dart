import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/widgets/empty_state.dart';
import 'package:logiq/models/transporter.dart';
import 'package:logiq/providers/admin_provider.dart';

class AdminTransportersScreen extends StatefulWidget {
  const AdminTransportersScreen({super.key});

  @override
  State<AdminTransportersScreen> createState() => _AdminTransportersScreenState();
}

class _AdminTransportersScreenState extends State<AdminTransportersScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final allTransporters = adminProvider.transporters;

    final filtered = allTransporters.where((t) {
      if (_statusFilter == 'Approved' && !t.isApproved) return false;
      if (_statusFilter == 'Pending' && t.isApproved) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return t.companyName.toLowerCase().contains(q) ||
          t.gstin.toLowerCase().contains(q) ||
          t.vahanId.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Transporters & Carriers',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search company, GSTIN, VAHAN...',
                    hintStyle: const TextStyle(color: AppColors.inkFaint, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.inkSoft),
                    filled: true,
                    fillColor: AppColors.surfaceCanvas,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.logiqGreen),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    _buildFilterChip('All', allTransporters.length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Approved', allTransporters.where((t) => t.isApproved).length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending', allTransporters.where((t) => !t.isApproved).length),
                  ],
                ),
              ),
              Container(color: AppColors.outline, height: 1),
            ],
          ),
        ),
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.logiqGreen))
          : RefreshIndicator(
              onRefresh: () => context.read<AdminProvider>().loadDashboard(),
              color: AppColors.logiqGreen,
              child: filtered.isEmpty
                  ? const EmptyState(
                      icon: Icons.local_shipping_outlined,
                      title: 'No Transporters Found',
                      subtitle: 'No transporters match your criteria.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final t = filtered[index];
                        return _buildTransporterCard(context, t);
                      },
                    ),
            ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _statusFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : AppColors.surfaceCanvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.ink : AppColors.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.inkSoft,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.outline,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransporterCard(BuildContext context, Transporter t) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  t.companyName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: t.isApproved ? AppColors.logiqGreenBg : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: t.isApproved ? AppColors.logiqGreenBorder : AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  t.isApproved ? 'Approved' : 'Pending',
                  style: TextStyle(
                    color: t.isApproved ? AppColors.logiqGreen : AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('GSTIN: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
              Text(t.gstin, style: const TextStyle(fontSize: 12, color: AppColors.ink)),
              if (t.vahanId.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Text('VAHAN: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                Text(t.vahanId, style: const TextStyle(fontSize: 12, color: AppColors.ink)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Container(color: AppColors.outline, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Approval Status',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
              ),
              Switch(
                value: t.isApproved,
                activeTrackColor: AppColors.logiqGreen,
                activeThumbColor: AppColors.white,
                onChanged: (approved) async {
                  if (approved) {
                    await context.read<AdminProvider>().approveUser(t.userId);
                  } else {
                    await context.read<AdminProvider>().rejectUser(t.userId);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Status updated for ${t.companyName}'),
                        backgroundColor: approved ? AppColors.logiqGreen : AppColors.danger,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
