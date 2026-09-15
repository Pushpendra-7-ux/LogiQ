import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ConnectionIndicator extends StatelessWidget {
  final bool isConnected;
  const ConnectionIndicator({super.key, required this.isConnected});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? AppColors.liveGreen : AppColors.error,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isConnected ? 'LIVE' : 'Reconnecting...',
            style: TextStyle(
              fontSize: 12,
              color: isConnected ? AppColors.liveGreen : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
}