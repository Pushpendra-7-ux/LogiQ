import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/widgets/stitch_header.dart';
import 'package:logiq/providers/admin_provider.dart';
import 'package:logiq/providers/tender_provider.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboard();
      context.read<TenderProvider>().loadAllTenders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final tenderProv = context.read<TenderProvider>();

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: const StitchHeader(
        roleBadge: 'CARRIER',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await adminProv.loadDashboard();
          if (mounted) {
            await tenderProv.loadAllTenders();
          }
        },
        color: AppColors.secondary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Telemetry strip + System Admin Title + Switch View
              _buildTelemetryHeader(),
              const SizedBox(height: 16),

              // 2x2 Metric Grid
              _buildAdminMetricGrid(adminProv),
              const SizedBox(height: 20),

              // Quick Operations Horizontal Scroll
              _buildQuickOperations(),
              const SizedBox(height: 24),

              // Live Reverse Auctions Section
              _buildLiveAuctionsSection(),
              const SizedBox(height: 24),

              // System Alerts & Compliance Section
              _buildSystemAlertsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.emeraldSuccess,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE FLEET TELEMETRY',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.shield, size: 13, color: AppColors.emeraldSuccess),
                  SizedBox(width: 4),
                  Text(
                    '99.9% Uptime',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.surfaceNavy,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'System Admin',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.surfaceNavy,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Operations & Reverse Tender Command',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () {
                context.go('/home');
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.sync_alt, size: 14, color: AppColors.surfaceNavy),
                    SizedBox(width: 4),
                    Text(
                      'Switch View',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.surfaceNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminMetricGrid(AdminProvider admin) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.45,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Tile 1: Active Auctions
        _buildMetricCard(
          title: 'ACTIVE AUCTIONS',
          topTrailing: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.emeraldSuccess,
              shape: BoxShape.circle,
            ),
          ),
          value: admin.activeTenderCount > 0 ? admin.activeTenderCount.toString() : '12',
          subWidget: Row(
            children: const [
              Icon(Icons.timer_outlined, size: 13, color: AppColors.emeraldSuccess),
              SizedBox(width: 3),
              Text(
                '3 ending < 15m',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.emeraldSuccess,
                ),
              ),
            ],
          ),
        ),

        // Tile 2: Total Savings
        _buildMetricCard(
          title: 'TOTAL SAVINGS',
          topTrailing: const Icon(Icons.trending_down, size: 18, color: AppColors.secondary),
          value: '₹4.2L',
          subWidget: RichText(
            text: const TextSpan(
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.inkSoft),
              children: [
                TextSpan(
                  text: '8.4% ',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.emeraldSuccess),
                ),
                TextSpan(text: 'below reserve'),
              ],
            ),
          ),
        ),

        // Tile 3: Participation
        _buildMetricCard(
          title: 'PARTICIPATION',
          topTrailing: const Icon(Icons.groups, size: 18, color: AppColors.secondary),
          value: '94%',
          subWidget: const Text(
            '48 active transporters',
            style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.inkSoft),
          ),
        ),

        // Tile 4: Pending Review
        _buildMetricCard(
          title: 'PENDING REGISTRATIONS',
          topTrailing: const Icon(Icons.pending_actions_rounded, size: 18, color: AppColors.roseAlert),
          value: admin.pendingApprovalCount.toString(),
          valueColor: AppColors.roseAlert,
          subWidget: Text(
            admin.pendingApprovalCount > 0
                ? '${admin.pendingApprovalCount} awaiting approval · Tap to review'
                : 'All caught up · Tap to view all',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.inkSoft),
          ),
          onTap: () => context.push('/admin/approvals'),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required Widget topTrailing,
    required String value,
    required Widget subWidget,
    Color valueColor = AppColors.surfaceNavy,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  topTrailing,
                ],
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                ),
              ),
              subWidget,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickOperations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK OPERATIONS',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildOperationBtn(
                icon: Icons.add_circle,
                label: 'New Spot Tender',
                isPrimary: true,
                onTap: () => context.push('/tender/create'),
              ),
              const SizedBox(width: 8),
              _buildOperationBtn(
                icon: Icons.local_shipping,
                label: 'Transporters',
                iconColor: AppColors.secondary,
                onTap: () => context.push('/admin/users'),
              ),
              const SizedBox(width: 8),
              _buildOperationBtn(
                icon: Icons.query_stats,
                label: 'Price Index',
                iconColor: AppColors.inkSoft,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _buildOperationBtn(
                icon: Icons.download,
                label: 'Bidding Logs',
                iconColor: AppColors.inkSoft,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOperationBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.surfaceNavy : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary ? AppColors.surfaceNavy : AppColors.borderSubtle,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: isPrimary ? Colors.white : (iconColor ?? AppColors.surfaceNavy),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isPrimary ? Colors.white : AppColors.surfaceNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveAuctionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Live Reverse Auctions',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.surfaceNavy,
                  ),
                ),
                Text(
                  'Multi-stage Procurement Monitor',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => context.push('/admin/tenders'),
              child: Row(
                children: const [
                  Text(
                    'View All (12)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: AppColors.secondary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Live Auction Card 1: TDR-8924 (Stage 1 Open)
        _buildAuctionCard(
          ref: 'TDR-8924',
          stageLabel: 'Stage 1 Open',
          stageColor: AppColors.emeraldSuccess,
          route: 'Gwalior → Raipur',
          specs: '25 MT Flatbed Trailer · Industrial Coil',
          timerText: '08:42',
          timerTag: 'Anti-sniping Active',
          timerTagColor: const Color(0xFFB45309),
          timerBgColor: const Color(0xFFFEF3C7),
          col1Title: 'RESERVE TARGET',
          col1Val: '₹52,000',
          col1Strike: true,
          col2Title: 'CURRENT L1 LEAD',
          col2Val: '₹48,800',
          col2Color: AppColors.emeraldSuccess,
          col3Title: 'PARTICIPATION',
          col3Val: '12 Bids · 4 LPs',
          l1LeadName: 'Shiv Shakti Logistics',
          primaryBtnLabel: 'Monitor Live',
          primaryBtnAction: () => context.push('/tender/1/live'),
        ),
        const SizedBox(height: 12),

        // Live Auction Card 2: TDR-8920 (Sealed Stage 2)
        _buildAuctionCard(
          ref: 'TDR-8920',
          stageLabel: 'Sealed Stage 2',
          stageColor: AppColors.secondary,
          route: 'Pune → Vapi',
          specs: '32 MT High Cube Container · FMCG Consignment',
          timerText: '03:15',
          timerTag: 'Final 5m Blind Window',
          timerTagColor: AppColors.roseAlert,
          timerBgColor: AppColors.roseAlert.withValues(alpha: 0.12),
          col1Title: 'STAGE 1 BASELINE',
          col1Val: '₹64,500',
          col2Title: 'CEILING BEST',
          col2Val: '₹62,100',
          col2Color: AppColors.secondary,
          col3Title: 'BLIND BIDS',
          col3Val: '5 Transporters',
          isSealed: true,
          primaryBtnLabel: 'Sealed Console',
          primaryBtnAction: () => context.push('/tender/2/live'),
        ),
      ],
    );
  }

  Widget _buildAuctionCard({
    required String ref,
    required String stageLabel,
    required Color stageColor,
    required String route,
    required String specs,
    required String timerText,
    required String timerTag,
    required Color timerTagColor,
    required Color timerBgColor,
    required String col1Title,
    required String col1Val,
    bool col1Strike = false,
    required String col2Title,
    required String col2Val,
    Color col2Color = AppColors.surfaceNavy,
    required String col3Title,
    required String col3Val,
    String? l1LeadName,
    bool isSealed = false,
    required String primaryBtnLabel,
    required VoidCallback primaryBtnAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with ref, badge & timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ref,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.surfaceNavy,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: stageColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          stageLabel,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: stageColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    route,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.surfaceNavy,
                    ),
                  ),
                  Text(
                    specs,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: timerBgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 12, color: timerTagColor),
                        const SizedBox(width: 4),
                        Text(
                          timerText,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: timerTagColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timerTag,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: timerTagColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3-Column stats row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      col1Title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      col1Val,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.surfaceNavy,
                        decoration: col1Strike ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      col2Title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      col2Val,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: col2Color,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      col3Title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      col3Val,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.surfaceNavy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Footer row (L1 info or lock notice + action buttons)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isSealed)
                Row(
                  children: const [
                    Icon(Icons.lock, size: 14, color: AppColors.secondary),
                    SizedBox(width: 4),
                    Text(
                      'Ranks concealed till tender close',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.blueSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'L1',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l1LeadName ?? 'Shiv Shakti Logistics',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.surfaceNavy,
                      ),
                    ),
                  ],
                ),

              Row(
                children: [
                  if (!isSealed) ...[
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Audit log exported for tender.')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        side: const BorderSide(color: AppColors.borderSubtle),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text(
                        'Audit Log',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.surfaceNavy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  ElevatedButton(
                    onPressed: primaryBtnAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSealed ? AppColors.secondary : AppColors.surfaceNavy,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text(
                      primaryBtnLabel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'System Alerts & Compliance',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.surfaceNavy,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.roseAlert.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '2 Action Items',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.roseAlert,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Alert 1: Carrier Flagged
        _buildAlertCard(
          icon: Icons.verified_user,
          iconBg: AppColors.roseAlert.withValues(alpha: 0.12),
          iconColor: AppColors.roseAlert,
          title: 'Carrier Fleet King Flagged',
          timeAgo: '4m ago',
          desc: 'GST verification pending for Stage 2 participation approval.',
          actionBtnLabel: 'Review KYC',
          onAction: () => context.push('/admin/users'),
        ),
        const SizedBox(height: 10),

        // Alert 2: Anti-Sniping Triggered
        _buildAlertCard(
          icon: Icons.av_timer,
          iconBg: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFB45309),
          title: 'Anti-Sniping Triggered',
          timeAgo: 'Just now',
          desc: '+30s auto-extended for TDR-8924 following sub-minute bid.',
          actionBtnLabel: 'View Event',
          onAction: () => context.push('/tender/1/live'),
        ),
      ],
    );
  }

  Widget _buildAlertCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String timeAgo,
    required String desc,
    required String actionBtnLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.surfaceNavy,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceAlt,
                        foregroundColor: AppColors.surfaceNavy,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(color: AppColors.borderSubtle),
                        ),
                      ),
                      child: Text(
                        actionBtnLabel,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () {},
                      child: const Text(
                        'Dismiss',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
