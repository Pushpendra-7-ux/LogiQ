import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/utils/haptics.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/providers/tender_provider.dart';
import 'package:logiq/providers/auction_provider.dart';
import 'package:logiq/models/tender.dart';

class Stage2LiveScreen extends StatefulWidget {
  final int tenderId;

  const Stage2LiveScreen({super.key, required this.tenderId});

  @override
  State<Stage2LiveScreen> createState() => _Stage2LiveScreenState();
}

class _Stage2LiveScreenState extends State<Stage2LiveScreen> {
  int _activeStage = 1; // 1 = Stage 1 Live Console (Screenshot 10), 2 = Stage 2 Blind Bid (Screenshot 6)
  late TextEditingController _bidController;
  bool _inclusiveDeclaration = true;

  @override
  void initState() {
    super.initState();
    _bidController = TextEditingController(text: '49225');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAuction();
    });
  }

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  Future<void> _initAuction() async {
    final auctionProv = context.read<AuctionProvider>();
    final tenderProv = context.read<TenderProvider>();

    await auctionProv.loadAuction(widget.tenderId);
    if (!mounted) return;

    final tender = tenderProv.tenderById(widget.tenderId);
    if ((auctionProv.currentAuction != null && auctionProv.currentAuction!.currentStage == 2) ||
        tender?.status == TenderStatus.stage2) {
      setState(() {
        _activeStage = 2;
        _bidController.text = '48800';
      });
    } else {
      if (auctionProv.currentAuction == null || !auctionProv.currentAuction!.status.isRunning) {
        await auctionProv.startStage1();
      }
    }
  }

  void _decrementBid(double amount) {
    Haptics.light();
    final current = double.tryParse(_bidController.text) ?? 49225.0;
    final next = (current - amount).clamp(1000.0, 1000000.0);
    setState(() {
      _bidController.text = next.toStringAsFixed(0);
    });
  }

  Future<void> _submitBid() async {
    final auctionProv = context.read<AuctionProvider>();
    final auth = context.read<AuthProvider>();
    final transporterId = auth.currentTransporter?.id ?? 1;
    final amount = double.tryParse(_bidController.text);

    if (amount == null || amount <= 0) return;

    Haptics.bidSubmitted();
    final success = await auctionProv.placeBid(transporterId, amount, _activeStage);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bid of ₹${amount.toInt()} placed successfully!'),
          backgroundColor: AppColors.emeraldSuccess,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenderProv = context.watch<TenderProvider>();
    final auctionProv = context.watch<AuctionProvider>();
    final auth = context.watch<AuthProvider>();

    final tender = tenderProv.tenderById(widget.tenderId);
    final myTransporterId = auth.currentTransporter?.id ?? 1;

    // Check if finished
    if (auctionProv.isFinalized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pushReplacement('/tender/${widget.tenderId}/result');
      });
    }

    final secondsRemaining = auctionProv.secondsRemaining;
    final minutes = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsRemaining % 60).toString().padLeft(2, '0');
    final timeStr = '01:$minutes:$seconds';

    final lowestBid = auctionProv.rankings.isNotEmpty ? auctionProv.rankings.first.amount : 49250.0;
    final myBid = auctionProv.myBidAmount(myTransporterId) ?? 49500.0;
    final myRank = auctionProv.myRank(myTransporterId);

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: _buildStitchAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: _activeStage == 1
                  ? _buildStage1Content(context, tender, timeStr, lowestBid, myBid, myRank, auctionProv)
                  : _buildStage2Content(context, tender, timeStr, lowestBid, myBid),
            ),
          ),
          _activeStage == 1
              ? _buildStage1BottomTray(context, lowestBid)
              : _buildStage2BottomTray(context),
        ],
      ),
    );
  }

  // Exact Stitch Header for Auction
  PreferredSizeWidget _buildStitchAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.navy, size: 20),
        onPressed: () => context.pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          // Logo Mark
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Icon(Icons.trending_up, size: 18, color: AppColors.electricBlue),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _activeStage == 1 ? 'LOGIQ  AUCTION' : 'LOGIQ  Stage 2 · Blind Bid',
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          if (_activeStage == 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: AppColors.emeraldSuccess,
                  fontWeight: FontWeight.w900,
                  fontSize: 10.5,
                ),
              ),
            ),
        ],
      ),
      actions: [
        // Stage switcher test trigger
        IconButton(
          icon: Icon(
            _activeStage == 1 ? Icons.lock_outline : Icons.visibility_outlined,
            color: AppColors.secondary,
            size: 20,
          ),
          tooltip: _activeStage == 1 ? 'Switch to Stage 2' : 'Switch to Stage 1',
          onPressed: () {
            setState(() {
              _activeStage = _activeStage == 1 ? 2 : 1;
              _bidController.text = _activeStage == 1 ? '49225' : '48800';
            });
          },
        ),
        Container(
          margin: const EdgeInsets.only(right: 14),
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.navy,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 18),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.borderSubtle),
      ),
    );
  }

  // ================= STAGE 1 LIVE (Screenshot 10) =================
  Widget _buildStage1Content(
    BuildContext context,
    Tender? tender,
    String timeStr,
    double lowestBid,
    double myBid,
    int myRank,
    AuctionProvider auctionProv,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Route Badge: 🚛 GWALIOR → RAIPUR · 25 MT #8924
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_shipping, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Text(
                    '${tender?.pickup.toUpperCase() ?? 'GWALIOR'} → ${tender?.drop.toUpperCase() ?? 'RAIPUR'}',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '25 MT  #8924',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Dark Navy Timer Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceNavy,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.timer_outlined, color: Color(0xFFFCA5A5), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TIME REMAINING',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF450A0A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'CLOSING SOON',
                      style: TextStyle(
                        color: Color(0xFFFCA5A5),
                        fontWeight: FontWeight.w900,
                        fontSize: 9.5,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Min step: ₹25',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Driver Standing Comparator (2 Side-by-side Cards)
        Row(
          children: [
            // YOUR BID Card (Amber border)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'YOUR BID',
                          style: TextStyle(color: AppColors.slate, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            myRank > 0 ? 'RANK #$myRank' : 'RANK #2',
                            style: const TextStyle(color: Color(0xFFB45309), fontSize: 9.5, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${myBid.toInt()}',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '+₹250 vs L1',
                      style: TextStyle(color: Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // LOWEST (L1) Card (Emerald border)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.emeraldSuccess, width: 1.5),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LOWEST (L1)',
                          style: TextStyle(color: AppColors.slate, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'LEAD',
                          style: TextStyle(color: AppColors.emeraldSuccess, fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      '₹49,250',
                      style: TextStyle(
                        color: AppColors.emeraldSuccess,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Transporter D',
                      style: TextStyle(color: AppColors.emeraldSuccess, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Target Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'To take 1st place, bid:',
                style: TextStyle(color: AppColors.slate, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Text(
                  '≤ ₹49,225',
                  style: TextStyle(color: AppColors.emeraldSuccess, fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // LEADERBOARD TOP 5
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'LEADERBOARD',
              style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.3),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'TOP 5',
                style: TextStyle(color: AppColors.slate, fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Rank Rows matching Screenshot 10
        _buildLeaderboardRow(1, 'Transporter D', '₹49,250', isFirst: true),
        const SizedBox(height: 6),
        _buildLeaderboardRow(2, 'You (Transporter C)', '₹49,500', isMe: true),
        const SizedBox(height: 6),
        _buildLeaderboardRow(3, 'Transporter B', '₹49,750'),
        const SizedBox(height: 6),
        _buildLeaderboardRow(4, 'Transporter A', '₹50,000'),
        const SizedBox(height: 6),
        _buildLeaderboardRow(5, 'Transporter G', '₹50,100'),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLeaderboardRow(int rank, String name, String amount, {bool isFirst = false, bool isMe = false}) {
    Color borderColor = AppColors.borderSubtle;
    Color badgeColor = const Color(0xFFE2E8F0);
    Color badgeTextColor = AppColors.slate;

    if (isFirst) {
      borderColor = AppColors.emeraldSuccess;
      badgeColor = AppColors.emeraldSuccess;
      badgeTextColor = Colors.white;
    } else if (isMe) {
      borderColor = const Color(0xFFF59E0B);
      badgeColor = const Color(0xFFF59E0B);
      badgeTextColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isFirst ? const Color(0xFFF0FDF4) : (isMe ? const Color(0xFFFFFBEB) : Colors.white),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: (isFirst || isMe) ? 1.2 : 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: badgeTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                name,
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 13,
                  fontWeight: isMe ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ],
          ),
          Text(
            amount,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStage1BottomTray(BuildContext context, double lowestBid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        boxShadow: [
          BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick 4 Steppers
            Row(
              children: [
                _buildStepperButton('-₹25', () => _decrementBid(25)),
                const SizedBox(width: 8),
                _buildStepperButton('-₹50', () => _decrementBid(50)),
                const SizedBox(width: 8),
                _buildStepperButton('-₹100', () => _decrementBid(100)),
                const SizedBox(width: 8),
                _buildStepperButton('-₹250', () => _decrementBid(250)),
              ],
            ),
            const SizedBox(height: 10),
            // Input + Submit CTA
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '₹',
                          style: TextStyle(color: AppColors.navy, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _bidController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.navy),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'L1',
                            style: TextStyle(color: AppColors.emeraldSuccess, fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitBid,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emeraldSuccess,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('SUBMIT BID', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperButton(String text, VoidCallback onTap) {
    return Expanded(
      child: SizedBox(
        height: 38,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFFF1F5F9),
            side: const BorderSide(color: AppColors.borderSubtle),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }

  // ================= STAGE 2 BLIND BID (Screenshot 6) =================
  Widget _buildStage2Content(
    BuildContext context,
    Tender? tender,
    String timeStr,
    double lowestBid,
    double myBid,
  ) {
    return Column(
      children: [
        // Route Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_shipping, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Text(
                    '${tender?.pickup.toUpperCase() ?? 'GWALIOR'} → ${tender?.drop.toUpperCase() ?? 'RAIPUR'}',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '25 MT Flatbed',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Navy Timer Box with SEALED BID pill
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceNavy,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TIME REMAINING',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        '05:49',
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 4),
                      Text('MIN', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock, size: 13, color: Color(0xFFFEF3C7)),
                    SizedBox(width: 4),
                    Text(
                      'SEALED BID',
                      style: TextStyle(color: Color(0xFFFEF3C7), fontSize: 10.5, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Core White Bid Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: [
              const Text(
                'YOUR SEALED TENDER',
                style: TextStyle(color: AppColors.slate, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              const SizedBox(height: 10),

              // Giant Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '₹',
                    style: TextStyle(color: AppColors.navy, fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 170,
                    child: TextField(
                      controller: _bidController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.navy, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Comparison Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_down, size: 14, color: AppColors.secondary),
                    SizedBox(width: 4),
                    Text(
                      'Stage 1: ₹49,500 (-₹700)',
                      style: TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4 Chips in 4 columns: [-₹100], [-₹250], [-₹500], [-₹1k]
              Row(
                children: [
                  _buildBlindChip('-₹100', () => _decrementBid(100)),
                  const SizedBox(width: 8),
                  _buildBlindChip('-₹250', () => _decrementBid(250)),
                  const SizedBox(width: 8),
                  _buildBlindChip('-₹500', () => _decrementBid(500)),
                  const SizedBox(width: 8),
                  _buildBlindChip('-₹1k', () => _decrementBid(1000)),
                ],
              ),
              const SizedBox(height: 16),

              // Checkbox declaration
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _inclusiveDeclaration,
                    activeColor: AppColors.navy,
                    onChanged: (val) => setState(() => _inclusiveDeclaration = val ?? true),
                  ),
                  const Text(
                    'All-inclusive final rate (Tolls, Tax, Fuel)',
                    style: TextStyle(color: AppColors.navy, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Trust badge
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 14, color: AppColors.slate),
            SizedBox(width: 4),
            Text(
              'Encrypted Vault Tender Engine',
              style: TextStyle(color: AppColors.slate, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBlindChip(String text, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStage2BottomTray(BuildContext context) {
    final val = _bidController.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submitBid,
                icon: const Icon(Icons.lock, size: 18, color: Colors.white),
                label: Text(
                  'SUBMIT ₹$val',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TR-8841', style: TextStyle(color: AppColors.slate, fontSize: 11, fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.emeraldSuccess, size: 12),
                    SizedBox(width: 3),
                    Text('System Online', style: TextStyle(color: AppColors.emeraldSuccess, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
