import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/core/widgets/empty_state.dart';
import 'package:logiq/models/user.dart';
import 'package:logiq/providers/admin_provider.dart';

enum RequestStatusFilter { pending, approved, rejected, all }

class AdminApprovalsScreen extends StatefulWidget {
  const AdminApprovalsScreen({super.key});

  @override
  State<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends State<AdminApprovalsScreen> {
  RequestStatusFilter _currentFilter = RequestStatusFilter.pending;
  String? _roleFilter; // null = all, 'user' = shipper, 'transporter' = transporter
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboard();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppUser> _getFilteredList(AdminProvider admin) {
    List<AppUser> list;
    switch (_currentFilter) {
      case RequestStatusFilter.pending:
        list = admin.pendingUsers;
        break;
      case RequestStatusFilter.approved:
        list = admin.approvedUsers;
        break;
      case RequestStatusFilter.rejected:
        list = admin.rejectedUsers;
        break;
      case RequestStatusFilter.all:
        list = admin.registrationRequests;
        break;
    }

    if (_roleFilter != null) {
      list = list.where((u) {
        if (_roleFilter == 'user') return u.isUser;
        return u.role == _roleFilter;
      }).toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((u) {
        return u.name.toLowerCase().contains(query) ||
            u.companyName.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query) ||
            u.phone.toLowerCase().contains(query);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final filteredList = _getFilteredList(adminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Registration Requests', style: AppTextStyles.h2),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Tabs & Search Bar
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by company, name, email...',
                    hintStyle: const TextStyle(color: AppColors.slate, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.slate),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16, color: AppColors.slate),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.slateFaint,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusFilterChip(
                        label: 'Pending',
                        count: adminProvider.pendingUsers.length,
                        filter: RequestStatusFilter.pending,
                        color: AppColors.amber,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip(
                        label: 'Approved',
                        count: adminProvider.approvedUsers.length,
                        filter: RequestStatusFilter.approved,
                        color: AppColors.emerald,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip(
                        label: 'Rejected',
                        count: adminProvider.rejectedUsers.length,
                        filter: RequestStatusFilter.rejected,
                        color: AppColors.roseAlert,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip(
                        label: 'All',
                        count: adminProvider.registrationRequests.length,
                        filter: RequestStatusFilter.all,
                        color: AppColors.navy,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Role Filter (All / Shippers / Transporters)
                Row(
                  children: [
                    const Text('Role: ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate)),
                    _buildRoleFilterChip('All', null),
                    const SizedBox(width: 6),
                    _buildRoleFilterChip('Users', 'user'),
                    const SizedBox(width: 6),
                    _buildRoleFilterChip('Transporters', 'transporter'),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.cardBorder),

          // Requests List
          Expanded(
            child: adminProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.electricBlue))
                : filteredList.isEmpty
                    ? const EmptyState(
                        icon: Icons.assignment_turned_in_outlined,
                        title: 'No Registrations Found',
                        subtitle: 'No registration requests match the selected filters.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredList.length,
                        separatorBuilder: (_, i) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final user = filteredList[index];
                          return _buildRequestCard(context, user);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip({
    required String label,
    required int count,
    required RequestStatusFilter filter,
    required Color color,
  }) {
    final isSelected = _currentFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _currentFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleFilterChip(String label, String? role) {
    final isSelected = _roleFilter == role;
    return GestureDetector(
      onTap: () => setState(() => _roleFilter = role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.navy : AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.slate,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, AppUser user) {
    final isShipper = user.isUser;
    final roleColor = isShipper ? AppColors.electricBlue : AppColors.emerald;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (user.status == AppUser.statusApproved) {
      statusColor = AppColors.emerald;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Approved';
    } else if (user.status == AppUser.statusRejected) {
      statusColor = AppColors.roseAlert;
      statusIcon = Icons.cancel_rounded;
      statusText = 'Rejected';
    } else {
      statusColor = AppColors.amber;
      statusIcon = Icons.hourglass_top_rounded;
      statusText = 'Pending';
    }

    final companyTitle = user.companyName.isNotEmpty ? user.companyName : user.name;
    final contactPerson = user.name;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Company Name + Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  companyTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Details
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  user.displayRole.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: roleColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: AppColors.slate),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        contactPerson,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Email & Phone
          Row(
            children: [
              const Icon(Icons.mail_outline_rounded, size: 13, color: AppColors.slate),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  user.email,
                  style: const TextStyle(fontSize: 12, color: AppColors.slate),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (user.phone.isNotEmpty) ...[
                const SizedBox(width: 10),
                const Icon(Icons.phone_android_rounded, size: 13, color: AppColors.slate),
                const SizedBox(width: 4),
                Text(
                  user.phone,
                  style: const TextStyle(fontSize: 12, color: AppColors.slate),
                ),
              ],
            ],
          ),

          // Registration date
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.inkFaint),
              const SizedBox(width: 5),
              Text(
                'Registered: ${_formatDate(user.createdAt)}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.inkFaint),
              ),
            ],
          ),

          // Rejection reason if present
          if (user.isRejected && user.rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.roseAlert.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.roseAlert.withValues(alpha: 0.25)),
              ),
              child: Text(
                'Rejection Note: ${user.rejectionReason}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.roseAlert,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],

          // Action Buttons: Accept / Reject (only shown if pending)
          if (user.isPending) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(context, user),
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.danger),
                  label: const Text('Reject', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _handleApprove(context, user),
                  icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                  label: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final m = months[dt.month - 1];
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $m ${dt.year}, $h:$min';
  }

  Future<void> _handleApprove(BuildContext context, AppUser user) async {
    if (user.id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final adminProvider = context.read<AdminProvider>();

    await adminProvider.approveRegistration(user.id!);

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('${user.companyName.isNotEmpty ? user.companyName : user.name} approved successfully.'),
        backgroundColor: AppColors.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showRejectDialog(BuildContext context, AppUser user) async {
    final messenger = ScaffoldMessenger.of(context);
    final adminProvider = context.read<AdminProvider>();
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.roseAlert),
            const SizedBox(width: 8),
            const Text('Reject Registration', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to reject the registration request for ${user.companyName.isNotEmpty ? user.companyName : user.name}?',
              style: const TextStyle(fontSize: 13.5, color: AppColors.navy),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection (optional)',
                hintText: 'e.g., Incomplete documentation, invalid GSTIN',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && user.id != null) {
      final reason = reasonController.text.trim();
      await adminProvider.rejectRegistration(
        user.id!,
        reason: reason.isNotEmpty ? reason : null,
      );

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${user.companyName.isNotEmpty ? user.companyName : user.name} has been rejected.'),
          backgroundColor: AppColors.navy,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
