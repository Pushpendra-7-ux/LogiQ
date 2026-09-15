import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ExtensionBanner extends StatelessWidget {
  final int extensionMinutes;
  final bool visible;

  const ExtensionBanner({
    super.key,
    required this.extensionMinutes,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, -1),
      duration: const Duration(milliseconds: 300),
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Auction Extended +$extensionMinutes minutes',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}