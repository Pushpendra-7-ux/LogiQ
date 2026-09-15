import 'package:flutter/material.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_colors.dart';

class BidSuccessOverlay extends StatefulWidget {
  final double amount;
  const BidSuccessOverlay({super.key, required this.amount});
  @override State<BidSuccessOverlay> createState() => _BidSuccessOverlayState();
}

class _BidSuccessOverlayState extends State<BidSuccessOverlay> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 72, color: AppColors.success),
            const SizedBox(height: 16),
            const Text('BID SUBMITTED', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Text(Formatters.currency(widget.amount), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 8),
            const Text('Your bid has been recorded.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}