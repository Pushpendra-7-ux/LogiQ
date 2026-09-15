import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_colors.dart';

class ResultScreen extends StatefulWidget {
  final int tenderId;
  const ResultScreen({super.key, required this.tenderId});
  @override State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
    _animCtrl.forward();
    context.read<AuctionProvider>().loadResult(widget.tenderId);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AuctionProvider>();
    final r = ap.result;

    return Scaffold(
      appBar: AppBar(title: const Text('AUCTION RESULT')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.rankL1.withValues(alpha: 0.15)),
                  child: const Icon(Icons.emoji_events, size: 80, color: AppColors.rankL1),
                ),
              ),
              const SizedBox(height: 24),
              const Text('WINNER FINALIZED', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              const Text('Automatic L1 Selection', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 24),
              if (r != null) ...[
                Text(r.winnerCompany ?? r.winnerName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 12),
                Text(Formatters.currency(r.winningBid), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.success)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.rankL1, borderRadius: BorderRadius.circular(16)),
                  child: const Text('L1 WINNER', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ] else ...[
                const CircularProgressIndicator(),
              ],
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  final role = context.read<AuthProvider>().role;
                  if (role == 'admin') {
                    context.go('/admin');
                  } else if (role == 'user') {
                    context.go('/user');
                  } else if (role == 'transporter') {
                    context.go('/transporter');
                  } else {
                    context.go('/splash');
                  }
                },
                child: const Text('BACK TO DASHBOARD'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}