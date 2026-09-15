import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData icon;
  final EdgeInsetsGeometry padding;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.icon = Icons.error_outline,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}