import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/validators.dart';
import '../../core/theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _userFormKey = GlobalKey<FormState>();
  final _transporterFormKey = GlobalKey<FormState>();

  // User fields
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // Transporter fields
  final _compNameCtrl = TextEditingController();
  final _compEmailCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _transportIdCtrl = TextEditingController();
  final _tPassCtrl = TextEditingController();
  final _tConfirmPassCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passCtrl.dispose(); _confirmPassCtrl.dispose();
    _compNameCtrl.dispose(); _compEmailCtrl.dispose(); _whatsappCtrl.dispose();
    _gstCtrl.dispose(); _transportIdCtrl.dispose();
    _tPassCtrl.dispose(); _tConfirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitUser() async {
    if (!_userFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final err = await auth.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      password: _passCtrl.text,
      role: 'user',
    );
    if (!mounted) return;
    if (err == null) {
      context.go('/auth/pending');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    }
  }

  Future<void> _submitTransporter() async {
    if (!_transporterFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final err = await auth.register(
      name: _compNameCtrl.text.trim(),
      email: _compEmailCtrl.text.trim(),
      password: _tPassCtrl.text,
      role: 'transporter',
      companyName: _compNameCtrl.text.trim(),
      companyEmail: _compEmailCtrl.text.trim(),
      whatsappPhone: _whatsappCtrl.text.trim(),
      gstNumber: _gstCtrl.text.trim().toUpperCase(),
      transportId: _transportIdCtrl.text.trim(),
    );
    if (!mounted) return;
    if (err == null) {
      context.go('/auth/pending');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Tender Maker'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Transporter'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // User form
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _userFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name'), validator: (v) => Validators.required(v, 'Name')),
                  const SizedBox(height: 16),
                  TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress, validator: Validators.email),
                  const SizedBox(height: 16),
                  TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number'), keyboardType: TextInputType.phone, validator: Validators.phone),
                  const SizedBox(height: 16),
                  TextFormField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true, validator: Validators.password),
                  const SizedBox(height: 16),
                  TextFormField(controller: _confirmPassCtrl, decoration: const InputDecoration(labelText: 'Confirm Password'), obscureText: true, validator: (v) => Validators.confirmPassword(v, _passCtrl.text)),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: auth.isLoading ? null : _submitUser, child: const Text('Register as Tender Maker')),
                ],
              ),
            ),
          ),
          // Transporter form
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _transporterFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(controller: _compNameCtrl, decoration: const InputDecoration(labelText: 'Company Name'), validator: (v) => Validators.required(v, 'Company Name')),
                  const SizedBox(height: 16),
                  TextFormField(controller: _compEmailCtrl, decoration: const InputDecoration(labelText: 'Company Email'), keyboardType: TextInputType.emailAddress, validator: Validators.email),
                  const SizedBox(height: 16),
                  TextFormField(controller: _whatsappCtrl, decoration: const InputDecoration(labelText: 'WhatsApp Phone Number'), keyboardType: TextInputType.phone, validator: Validators.phone),
                  const SizedBox(height: 16),
                  TextFormField(controller: _gstCtrl, decoration: const InputDecoration(labelText: 'GSTIN Number (15 chars)'), textCapitalization: TextCapitalization.characters, validator: Validators.gst),
                  const SizedBox(height: 16),
                  TextFormField(controller: _transportIdCtrl, decoration: const InputDecoration(labelText: 'Transport ID / License'), validator: (v) => Validators.required(v, 'Transport ID')),
                  const SizedBox(height: 16),
                  TextFormField(controller: _tPassCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true, validator: Validators.password),
                  const SizedBox(height: 16),
                  TextFormField(controller: _tConfirmPassCtrl, decoration: const InputDecoration(labelText: 'Confirm Password'), obscureText: true, validator: (v) => Validators.confirmPassword(v, _tPassCtrl.text)),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: auth.isLoading ? null : _submitTransporter, child: const Text('Register as Transporter')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}