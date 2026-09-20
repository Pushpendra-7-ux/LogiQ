import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/widgets/stitch_header.dart';
import 'package:logiq/core/utils/haptics.dart';
import 'package:logiq/models/tender.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/providers/tender_provider.dart';
import 'package:logiq/providers/bid_provider.dart';

class TransporterHomeScreen extends StatefulWidget {
  const TransporterHomeScreen({super.key});

  @override
  State<TransporterHomeScreen> createState() => _TransporterHomeScreenState();
}

class _TransporterHomeScreenState extends State<TransporterHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    if (auth.currentTransporter?.id != null) {
      final id = auth.currentTransporter!.id!;
      await context.read<TenderProvider>().loadTendersForTransporter(id);
      if (!mounted) return;
      await context.read<BidProvider>().loadBidsForTransporter(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bidProv = context.watch<BidProvider>();
    final tenderProv = context.watch<TenderProvider>();
    final activeTenders = tenderProv.activeTenders;

    final companyName = auth.currentTransporter?.companyName ?? 'Apex Freight';
    final activeBidsCount = bidProv.activeBids.isNotEmpty ? bidProv.activeBids.length : 4;
    final wonBidsCount = bidProv.wonBids.isNotEmpty ? bidProv.wonBids.length : 2;

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: const StitchHeader(
        roleBadge: 'CARRIER',
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.secondary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Center(
                            child: Icon(Icons.person, color: Colors.white, size: 24),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.emeraldSuccess,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Center(
                              child: Icon(Icons.check, size: 8, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  companyName,
                                  style: const TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, size: 16, color: AppColors.emeraldSuccess),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'KA-04 FLEET OPS',
                            style: TextStyle(
                              color: AppColors.slate,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.amberSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.star, size: 14, color: Color(0xFFD97706)),
                          SizedBox(width: 3),
                          Text(
                            '4.9',
                            style: TextStyle(
                              color: Color(0xFFB45309),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCol(
                      title: 'ACTIVE BIDS',
                      value: '$activeBidsCount',
                      valueColor: AppColors.secondary,
                      subtext: '📈 2 Lead',
                      subtextColor: AppColors.emeraldSuccess,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCol(
                      title: 'WON TODAY',
                      value: '$wonBidsCount',
                      valueColor: AppColors.navy,
                      subtext: '₹1.05L val',
                      subtextColor: AppColors.slate,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCol(
                      title: 'L1 WIN RATE',
                      value: '75%',
                      valueColor: AppColors.emeraldSuccess,
                      subtext: 'Top Tier',
                      subtextColor: AppColors.slate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceNavy,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F0F172A),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.roseAlert.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.circle, size: 7, color: AppColors.roseAlert),
                              SizedBox(width: 4),
                              Text(
                                'OUTBID WARNING',
                                style: TextStyle(
                                  color: Color(0xFFFCA5A5),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.amberSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.timer_outlined, size: 13, color: Color(0xFFD97706)),
                              SizedBox(width: 4),
                              Text(
                                '06:10',
                                style: TextStyle(
                                  color: Color(0xFFB45309),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '#TDR-8924',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.roseAlert.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'You are L2 · Lag ₹75',
                            style: TextStyle(
                              color: Color(0xFFFCA5A5),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Gwalior (GWL) → Raipur (RPR)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '25 MT Flatbed • Steel Wire Coils',
                      style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF213145),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CURRENT L1 BID', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w700)),
                              SizedBox(height: 2),
                              Text('₹48,800', style: TextStyle(color: AppColors.emeraldSuccess, fontSize: 18, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('YOUR PREV BID', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w700)),
                              SizedBox(height: 2),
                              Text('₹48,875', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Haptics.bidSubmitted();
                          context.push('/tender/1/live');
                        },
                        icon: const Icon(Icons.bolt, color: Colors.white, size: 18),
                        label: const Text(
                          'Drop to ₹48,775 & Take L1',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emeraldSuccess,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.swap_calls_rounded, size: 18, color: AppColors.secondary),
                      SizedBox(width: 6),
                      Text(
                        'Active Live Auctions',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => context.go('/transporter/available'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${activeTenders.isNotEmpty ? activeTenders.length : 3} Available',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (activeTenders.isNotEmpty)
                ...activeTenders.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildDynamicTenderCard(context, t),
                  ),
                )
              else ...[
                _buildAuctionCard1(context),
                const SizedBox(height: 10),
                _buildAuctionCard2(context),
                const SizedBox(height: 10),
                _buildAuctionCard3(context),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ACTIVE TRANSIT CORRIDOR',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Live GPS Active',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Stack(
                  children: [
                    CustomPaint(
                      size: const Size(double.infinity, 140),
                      painter: _MockRoadPainter(),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.navy.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.circle, size: 7, color: AppColors.emeraldSuccess),
                            SizedBox(width: 6),
                            Text(
                              'Apex Fleet 08 · On Route (ETA 3h 12m)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.local_shipping_outlined,
                      iconColor: AppColors.secondary,
                      title: 'Assigned Trips',
                      subtitle: '3 vehicles moving',
                      onTap: () => context.push('/bids'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.badge_outlined,
                      iconColor: AppColors.secondary,
                      title: 'Fleet Drivers',
                      subtitle: '12 Active & Ready',
                      onTap: () => context.push('/bids'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.receipt_long_outlined,
                      iconColor: const Color(0xFFD97706),
                      title: 'E-Way Bills',
                      subtitle: 'Direct GST Sync',
                      onTap: () => context.push('/bids'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.archive_outlined,
                      iconColor: AppColors.secondary,
                      title: 'Won Archives',
                      subtitle: 'Completed Contracts',
                      onTap: () => context.push('/bids'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol({
    required String title,
    required String value,
    required Color valueColor,
    required String subtext,
    required Color subtextColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.slate,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: TextStyle(
              color: subtextColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicTenderCard(BuildContext context, Tender tender) {
    final isLive = tender.status == TenderStatus.stage1 || tender.status == TenderStatus.stage2;
    final statusColor = isLive ? AppColors.roseAlert : AppColors.secondary;
    final statusBg = isLive ? AppColors.roseAlert.withValues(alpha: 0.15) : const Color(0xFFEFF6FF);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#TDR-${tender.id ?? "---"}',
                style: const TextStyle(
                  color: AppColors.slate,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      tender.status == TenderStatus.stage2
                          ? Icons.bolt
                          : (tender.status == TenderStatus.stage1 ? Icons.gavel : Icons.schedule),
                      size: 12,
                      color: statusColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      tender.status.label,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tender.shortRoute,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.navy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tender.vehicleType} • ${tender.title}',
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'CEILING CAP',
                    style: TextStyle(
                      color: AppColors.slate,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${tender.ceilingBid.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_outlined, size: 14, color: AppColors.emeraldSuccess),
                  SizedBox(width: 4),
                  Text(
                    'Verified Eligible Fleet',
                    style: TextStyle(
                      color: AppColors.emeraldSuccess,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  if (tender.status == TenderStatus.stage2) {
                    context.push('/tender/${tender.id}/live');
                  } else if (tender.status == TenderStatus.completed) {
                    context.push('/tender/${tender.id}/result');
                  } else {
                    context.push('/tender/${tender.id}/bid');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: tender.status == TenderStatus.stage2 ? AppColors.navy : AppColors.secondary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(0, 34),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  tender.status == TenderStatus.stage2
                      ? 'Enter Arena'
                      : (tender.status == TenderStatus.completed ? 'View Results' : 'Place Bid'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionCard1(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.circle, size: 7, color: AppColors.roseAlert),
                  SizedBox(width: 5),
                  Text('#TDR-8924', style: TextStyle(color: AppColors.slate, fontWeight: FontWeight.w700, fontSize: 11.5)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.roseAlert.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'L2 Trailing',
                  style: TextStyle(color: AppColors.roseAlert, fontWeight: FontWeight.w800, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gwalior → Raipur', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.navy)),
                  SizedBox(height: 2),
                  Text('25 MT • Flatbed • 620 km', style: TextStyle(color: AppColors.slate, fontSize: 11)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('TARGET L1', style: TextStyle(color: AppColors.slate, fontSize: 9.5, fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('₹48,800', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.navy)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () {
                      Haptics.light();
                      context.push('/tender/1/live');
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFF6FF),
                      side: const BorderSide(color: Color(0xFFDBEAFE)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('-₹25', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () {
                      Haptics.light();
                      context.push('/tender/1/live');
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFF6FF),
                      side: const BorderSide(color: Color(0xFFDBEAFE)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('-₹50', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () {
                      Haptics.light();
                      context.push('/tender/1/live');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Enter Arena', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionCard2(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('#TDR-8931', style: TextStyle(color: AppColors.slate, fontWeight: FontWeight.w700, fontSize: 11.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.schedule, size: 12, color: AppColors.secondary),
                    SizedBox(width: 3),
                    Text('Starts in 25m', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Indore → Ahmedabad', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.navy)),
                  SizedBox(height: 2),
                  Text('18 MT • Tautliner • Pharma Pack', style: TextStyle(color: AppColors.slate, fontSize: 11)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('CEILING CAP', style: TextStyle(color: AppColors.slate, fontSize: 9.5, fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('₹38,000', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.navy)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_outlined, size: 14, color: AppColors.emeraldSuccess),
                  SizedBox(width: 4),
                  Text('Verified Eligible Fleet', style: TextStyle(color: AppColors.emeraldSuccess, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
              ElevatedButton(
                onPressed: () => context.push('/tender/1/bid'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(0, 34),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Pre-Register Bid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionCard3(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('#TDR-8918', style: TextStyle(color: AppColors.slate, fontWeight: FontWeight.w700, fontSize: 11.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.emoji_events, size: 12, color: AppColors.emeraldSuccess),
                    SizedBox(width: 3),
                    Text('Awarded L1', style: TextStyle(color: AppColors.emeraldSuccess, fontWeight: FontWeight.w800, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bilaspur → Nagpur', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.navy)),
                  SizedBox(height: 2),
                  Text('32 MT • Cement Bags • Loading 18:00', style: TextStyle(color: AppColors.slate, fontSize: 11)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('FINAL TENDER', style: TextStyle(color: AppColors.slate, fontSize: 9.5, fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('₹34,200', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.emeraldSuccess)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: AppColors.roseAlert),
                  SizedBox(width: 4),
                  Text('Driver Unassigned', style: TextStyle(color: AppColors.roseAlert, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
              ElevatedButton(
                onPressed: () => context.push('/tender/1/result'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(0, 34),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Row(
                  children: [
                    Text('Assign Truck', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_forward, size: 13),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.navy)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: AppColors.slate, fontSize: 10.5)),
          ],
        ),
      ),
    );
  }
}

class _MockRoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(20, size.height * 0.7);
    path.cubicTo(
      size.width * 0.3, size.height * 0.2,
      size.width * 0.6, size.height * 0.8,
      size.width - 20, size.height * 0.3,
    );
    canvas.drawPath(path, paint);

    final highlightPaint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final subPath = Path();
    subPath.moveTo(20, size.height * 0.7);
    subPath.cubicTo(
      size.width * 0.3, size.height * 0.2,
      size.width * 0.45, size.height * 0.45,
      size.width * 0.5, size.height * 0.5,
    );
    canvas.drawPath(subPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
