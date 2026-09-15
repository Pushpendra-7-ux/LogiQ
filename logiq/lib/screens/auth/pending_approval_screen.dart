import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.hourglass_top_rounded, size: 80, color: AppColors.warning),
              const SizedBox(height: 24),
              const Text('Approval Pending', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text(
                'Your account has been registered successfully and is currently under review by our administration team. Once approved, you will be able to log in and participate.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<AuthProvider>().logout();
                  context.go('/auth/login');
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}