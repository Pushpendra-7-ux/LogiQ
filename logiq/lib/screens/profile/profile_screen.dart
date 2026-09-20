import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/core/theme/app_dimensions.dart';
import 'package:logiq/core/widgets/big_button.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/providers/navigation_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.inkSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      context.read<NavigationProvider>().resetIndex();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final transporter = authProvider.currentTransporter;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';

    final primaryColor = authProvider.isUser ? AppColors.logiqGreen : AppColors.electricBlue;
    final badgeBgColor = authProvider.isUser ? AppColors.logiqGreenBg : AppColors.electricBlueLight;
    final badgeBorderColor = authProvider.isUser ? AppColors.logiqGreenBorder : AppColors.electricBlueBorder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.ink,
        leading: (context.canPop() || authProvider.isUser)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
              )
            : null,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          children: [
            const SizedBox(height: AppDimensions.xl),
            CircleAvatar(
              radius: 32,
              backgroundColor: primaryColor,
              child: Text(
                initial,
                style: AppTextStyles.h1.copyWith(color: Colors.white),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: AppDimensions.md),
            Text(user.name, style: AppTextStyles.h2).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: AppDimensions.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.xs),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: badgeBorderColor),
              ),
              child: Text(
                authProvider.userRole.toUpperCase(),
                style: AppTextStyles.labelBold.copyWith(color: primaryColor),
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: AppDimensions.xxxl),
            
            _ProfileRow(icon: Icons.email, label: 'Email', value: user.email).animate().fadeIn(delay: 300.ms).slideX(),
            const Divider(height: AppDimensions.xxl),
            _ProfileRow(icon: Icons.phone, label: 'Phone', value: user.phone).animate().fadeIn(delay: 400.ms).slideX(),
            const Divider(height: AppDimensions.xxl),

            if (authProvider.isTransporter && transporter != null) ...[
              _ProfileRow(icon: Icons.business, label: 'Company Name', value: transporter.companyName).animate().fadeIn(delay: 500.ms).slideX(),
              const Divider(height: AppDimensions.xxl),
              _ProfileRow(icon: Icons.receipt, label: 'GSTIN', value: transporter.gstin).animate().fadeIn(delay: 600.ms).slideX(),
              const Divider(height: AppDimensions.xxl),
              _ProfileRow(icon: Icons.directions_car, label: 'Vahan ID', value: transporter.vahanId.isNotEmpty ? transporter.vahanId : 'N/A').animate().fadeIn(delay: 700.ms).slideX(),
              const Divider(height: AppDimensions.xxl),
            ],

            const SizedBox(height: AppDimensions.huge),
            BigButton(
              label: 'Logout',
              icon: Icons.logout,
              color: AppColors.danger,
              onPressed: () => _confirmLogout(context),
            ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.inkSoft, size: 24),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.inkSoft)),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.bodyStrong),
            ],
          ),
        ),
      ],
    );
  }
}
