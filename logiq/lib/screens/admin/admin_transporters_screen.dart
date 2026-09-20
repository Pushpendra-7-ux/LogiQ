import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/core/widgets/empty_state.dart';
import 'package:logiq/core/widgets/status_chip.dart';
import 'package:logiq/models/transporter.dart';
import 'package:logiq/providers/admin_provider.dart';

class AdminTransportersScreen extends StatefulWidget {
  const AdminTransportersScreen({super.key});

  @override
  State<AdminTransportersScreen> createState() => _AdminTransportersScreenState();
}

class _AdminTransportersScreenState extends State<AdminTransportersScreen> {
  String _searchQuery = '';

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
    final transporters = adminProvider.pendingTransporters.where((t) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return t.companyName.toLowerCase().contains(q) ||
          t.gstin.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transporters', style: AppTextStyles.h2),
        backgroundColor: AppColors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search company or GSTIN...',
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
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.electricBlue))
          : transporters.isEmpty
              ? const EmptyState(
                  icon: Icons.local_shipping_outlined,
                  title: 'No Transporters Found',
                  subtitle: 'No transporters match your search.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: transporters.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final t = transporters[index];
                    return _TransporterCard(
                      transporter: t,
                      onToggleApproval: (approved) async {
                        if (approved) {
                          await context.read<AdminProvider>().approveUser(t.userId);
                        } else {
                          await context.read<AdminProvider>().rejectUser(t.userId);
                        }
                      },
                    );
                  },
                ),
    );
  }
}

class _TransporterCard extends StatelessWidget {
  final Transporter transporter;
  final ValueChanged<bool> onToggleApproval;

  const _TransporterCard({
    required this.transporter,
    required this.onToggleApproval,
  });

  @override
  Widget build(BuildContext context) {
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
                  transporter.companyName,
                  style: AppTextStyles.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusChip(
                label: transporter.isApproved ? 'Approved' : 'Pending',
                color: transporter.isApproved ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'GSTIN: ${transporter.gstin}',
            style: AppTextStyles.body.copyWith(fontSize: 14, color: AppColors.inkSoft),
          ),
          if (transporter.vahanId.isNotEmpty)
            Text(
              'VAHAN: ${transporter.vahanId}',
              style: AppTextStyles.caption.copyWith(color: AppColors.inkFaint),
            ),
          const Divider(height: 20, color: AppColors.outline),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Approval Status',
                style: AppTextStyles.bodyStrong.copyWith(fontSize: 14),
              ),
              Switch(
                value: transporter.isApproved,
                activeTrackColor: AppColors.success,
                activeThumbColor: AppColors.white,
                onChanged: onToggleApproval,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
