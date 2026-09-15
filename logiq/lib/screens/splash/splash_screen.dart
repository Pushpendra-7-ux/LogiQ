import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final loggedIn = await auth.checkAuth();
    if (!mounted) return;
    if (loggedIn) {
      final role = auth.role;
      if (role == 'admin') {
        context.go('/admin');
      } else if (role == 'user') {
        context.go('/user');
      } else if (role == 'transporter') {
        context.go('/transporter');
      } else {
        context.go('/auth/login');
      }
    } else {
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.swap_vert_circle_rounded, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text('LOGIQ', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 4)),
            const SizedBox(height: 8),
            const Text('Reverse Auction System', style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 1.2)),
            const SizedBox(height: 48),
            const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
          ],
        ),
      ),
    );
  }
}