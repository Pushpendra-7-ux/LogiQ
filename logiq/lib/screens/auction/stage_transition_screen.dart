import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class StageTransitionScreen extends StatefulWidget {
  final int tenderId;
  const StageTransitionScreen({super.key, required this.tenderId});
  @override State<StageTransitionScreen> createState() => _StageTransitionScreenState();
}

class _StageTransitionScreenState extends State<StageTransitionScreen> {
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) setState(() => _step = 1);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) setState(() => _step = 2);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) context.go('/auction/${widget.tenderId}/stage2');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blindPurple,
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _buildStepContent(),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return Column(
          key: const ValueKey(0),
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text('STAGE 1 COMPLETE', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
          ],
        );
      case 1:
        return Column(
          key: const ValueKey(1),
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.filter_5, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text('TOP 5 TRANSPORTERS SELECTED', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
          ],
        );
      default:
        return Column(
          key: const ValueKey(2),
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.lock, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text('FINAL AUCTION', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
            SizedBox(height: 8),
            Text('Confidential Blind Bidding', style: TextStyle(fontSize: 16, color: Colors.white70)),
          ],
        );
    }
  }
}