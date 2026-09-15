import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/validators.dart';
import '../../core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailController.text.trim(), _passwordController.text);
    if (!mounted) return;
    if (ok) {
      final role = auth.role;
      if (role == 'admin') {
        context.go('/admin');
      } else if (role == 'user') {
        context.go('/user');
      } else if (role == 'transporter') {
        context.go('/transporter');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Login failed'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.swap_vert_circle_rounded, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text('Welcome to LogiQ', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Sign in to manage & bid in reverse auctions', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _submit,
                    child: auth.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign In'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.push('/auth/register'),
                    child: const Text("Don't have an account? Sign Up"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}