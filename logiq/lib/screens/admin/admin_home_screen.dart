import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/models/user.dart';
import 'package:logiq/providers/admin_provider.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/providers/tender_provider.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await context.read<AdminProvider>().loadDashboard();
    if (mounted) {
      await context.read<TenderProvider>().loadAllTenders();
    }
  }

  Future<void> _approveUser(AppUser user) async {
    if (user.id == null) return;
    await context.read<AdminProvider>().approveRegistration(user.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${user.name} approved successfully'),
        backgroundColor: AppColors.logiqGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _rejectUser(AppUser user) async {
    if (user.id == null) return;
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Registration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject ${user.name}?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AdminProvider>().rejectRegistration(
            user.id!,
            reason: reasonController.text.trim().isEmpty ? 'Application rejected by admin' : reasonController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} rejected'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final tenderProv = context.watch<TenderProvider>();
    final auth = context.watch<AuthProvider>();

    final adminName = auth.currentUser?.name ?? 'Admin';
    final initial = adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A';

    final pendingCount = adminProv.pendingUsers.length;
    final activeCount = tenderProv.activeTenders.length;
    final transporterCount = adminProv.totalTransporterCount;
    final userCount = adminProv.approvedUsers.where((u) => u.isUser).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(adminName, initial),
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
                        'Admin Dashboard',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Manage platform requests, tenders, and carrier approvals',
                        style: AppTextStyles.bodyMuted,
                      ),
                      const SizedBox(height: 24),

                      _HeroCard(
                        title: 'Registration Requests',
                        subtitle: pendingCount > 0
                            ? '$pendingCount pending approval'
                            : 'All accounts verified',
                        badgeText: '$pendingCount Pending',
                        onTap: () => context.push('/admin/approvals'),
                      ),
                      const SizedBox(height: 16),

                      _DashboardCard(
                        icon: Icons.cell_tower,
                        title: 'Active Tenders',
                        subtitle: 'Live reverse auctions & bidding',
                        badge: '$activeCount Live',
                        onTap: () => context.push('/admin/tenders'),
                      ),
                      const SizedBox(height: 16),

                      _DashboardCard(
                        icon: Icons.local_shipping_outlined,
                        title: 'Transporters',
                        subtitle: 'Fleet carriers & compliance',
                        badge: '$transporterCount Total',
                        onTap: () => context.push('/admin/transporters'),
                      ),
                      const SizedBox(height: 16),

                      _DashboardCard(
                        icon: Icons.business_outlined,
                        title: 'Shipper Accounts',
                        subtitle: 'Enterprise shippers & demand',
                        badge: '$userCount Active',
                        onTap: () => context.push('/admin/users'),
                      ),
                      const SizedBox(height: 28),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: pendingCount > 0 ? AppColors.warning : AppColors.logiqGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'PENDING REQUESTS ($pendingCount)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ],
                          ),
                          if (pendingCount > 0)
                            InkWell(
                              onTap: () => context.push('/admin/approvals'),
                              child: const Text(
                                'View All →',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.logiqGreen,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (pendingCount == 0)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: AppColors.logiqGreenBg,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: AppColors.logiqGreen, size: 24),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No Pending Requests',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'All user and transporter registrations have been reviewed.',
                                style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: adminProv.pendingUsers.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final user = adminProv.pendingUsers[index];
                            return _PendingRequestTile(
                              user: user,
                              formattedDate: _dateFormat.format(user.createdAt),
                              onApprove: () => _approveUser(user),
                              onReject: () => _rejectUser(user),
                            );
                          },
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

  Widget _buildAppBar(String adminName, String initial) {
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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCanvas,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.outline),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.inkSoft, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => context.push('/profile'),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  Text('Hi, $adminName', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
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

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badgeText;
  final VoidCallback onTap;

  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.onTap,
  });

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
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.how_to_reg, color: AppColors.white, size: 24),
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
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badgeText,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward, color: AppColors.logiqGreenDark, size: 20),
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.logiqGreenBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.logiqGreen, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title, style: AppTextStyles.h3),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.logiqGreenBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.logiqGreenBorder),
                              ),
                              child: Text(
                                badge!,
                                style: const TextStyle(
                                  color: AppColors.logiqGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
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
                const Icon(Icons.chevron_right, color: AppColors.inkFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingRequestTile extends StatelessWidget {
  final AppUser user;
  final String formattedDate;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingRequestTile({
    required this.user,
    required this.formattedDate,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isTransporter = user.isTransporter;
    final roleColor = isTransporter ? AppColors.logiqGreen : Colors.blue.shade700;
    final roleBg = isTransporter ? AppColors.logiqGreenBg : Colors.blue.shade50;
    final roleBorder = isTransporter ? AppColors.logiqGreenBorder : Colors.blue.shade200;
    final roleLabel = isTransporter ? 'CARRIER' : 'SHIPPER';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  user.companyName.isNotEmpty ? user.companyName : user.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: roleBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: roleBorder),
                ),
                child: Text(
                  roleLabel,
                  style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          if (user.companyName.isNotEmpty && user.name != user.companyName) ...[
            const SizedBox(height: 2),
            Text(user.name, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.email_outlined, size: 14, color: AppColors.inkSoft),
              const SizedBox(width: 4),
              Expanded(child: Text(user.email, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 14, color: AppColors.inkSoft),
              const SizedBox(width: 4),
              Text(user.phone, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
              const Spacer(),
              Text(formattedDate, style: const TextStyle(fontSize: 10, color: AppColors.inkFaint)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.logiqGreen,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
