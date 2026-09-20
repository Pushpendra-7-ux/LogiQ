import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/core/constants/app_constants.dart';
import 'package:logiq/core/constants/demo_constants.dart';
import 'package:logiq/core/utils/validators.dart';
import 'package:logiq/core/utils/haptics.dart';
import 'package:logiq/models/user.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/providers/navigation_provider.dart';

enum AuthRole {
  user('User', Icons.person_rounded, AppColors.electricBlue),
  transporter('Transporter', Icons.local_shipping_rounded, AppColors.emerald),
  admin('Admin', Icons.admin_panel_settings_rounded, AppColors.navy);

  final String title;
  final IconData icon;
  final Color color;

  const AuthRole(this.title, this.icon, this.color);
}

enum FormViewMode { signIn, signUp }

/// Main Role-Based Authentication Screen for LogiQ.
/// Strictly isolates User, Transporter, and Admin auth flows.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Current active role portal
  AuthRole _selectedRole = AuthRole.user;

  // Mode for User portal (signIn / signUp)
  FormViewMode _userMode = FormViewMode.signIn;

  // Mode for Transporter portal (signIn / signUp)
  FormViewMode _transporterMode = FormViewMode.signIn;

  // ── Controllers for Sign In ──
  final _signInFormKey = GlobalKey<FormState>();
  final _signInEmailController = TextEditingController(text: DemoConstants.userDemoEmail);
  final _signInPasswordController = TextEditingController(text: DemoConstants.userDemoPassword);
  bool _obscureSignInPassword = true;

  // ── Controllers for User Sign Up (Strictly 5 fields) ──
  final _userSignUpFormKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _userEmailController = TextEditingController();
  final _userPhoneController = TextEditingController();
  final _userPasswordController = TextEditingController();
  final _userConfirmPasswordController = TextEditingController();
  bool _obscureUserPassword = true;
  bool _obscureUserConfirmPassword = true;

  // ── Controllers for Transporter Sign Up (Strictly 7 fields) ──
  final _transporterSignUpFormKey = GlobalKey<FormState>();
  final _transporterCompanyNameController = TextEditingController();
  final _transporterGstinController = TextEditingController();
  final _transporterTransportIdController = TextEditingController();
  final _transporterEmailController = TextEditingController();
  final _transporterPhoneController = TextEditingController();
  final _transporterPasswordController = TextEditingController();
  final _transporterConfirmPasswordController = TextEditingController();
  bool _obscureTransporterPassword = true;
  bool _obscureTransporterConfirmPassword = true;

  @override
  void dispose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();

    _userNameController.dispose();
    _userEmailController.dispose();
    _userPhoneController.dispose();
    _userPasswordController.dispose();
    _userConfirmPasswordController.dispose();

    _transporterCompanyNameController.dispose();
    _transporterGstinController.dispose();
    _transporterTransportIdController.dispose();
    _transporterEmailController.dispose();
    _transporterPhoneController.dispose();
    _transporterPasswordController.dispose();
    _transporterConfirmPasswordController.dispose();
    super.dispose();
  }

  void _onRoleChanged(AuthRole role) {
    Haptics.selection();
    setState(() {
      _selectedRole = role;
      // Pre-fill demo credentials for convenience
      if (role == AuthRole.user) {
        _signInEmailController.text = DemoConstants.userDemoEmail;
        _signInPasswordController.text = DemoConstants.userDemoPassword;
      } else if (role == AuthRole.transporter) {
        _signInEmailController.text = DemoConstants.transporterDemoEmail;
        _signInPasswordController.text = DemoConstants.transporterDemoPassword;
      } else {
        _signInEmailController.text = DemoConstants.adminDemoEmail;
        _signInPasswordController.text = DemoConstants.adminDemoPassword;
      }
    });
  }

  // ── Sign In Submission ──
  Future<void> _handleSignIn() async {
    FocusScope.of(context).unfocus();
    if (!_signInFormKey.currentState!.validate()) return;

    Haptics.light();
    final auth = context.read<AuthProvider>();

    String expectedRole;
    if (_selectedRole == AuthRole.user) {
      expectedRole = AppUser.roleUser;
    } else if (_selectedRole == AuthRole.transporter) {
      expectedRole = AppUser.roleTransporter;
    } else {
      expectedRole = AppUser.roleAdmin;
    }

    final success = await auth.login(
      _signInEmailController.text.trim(),
      _signInPasswordController.text,
      expectedRole: expectedRole,
    );

    if (!mounted) return;

    if (success) {
      context.read<NavigationProvider>().resetIndex();
      context.go('/home');
    } else if (auth.isPending) {
      Haptics.warning();
      _showPendingDialog();
    } else if (auth.isRejected) {
      Haptics.error();
      _showRejectedDialog(auth.rejectionReason);
    } else {
      Haptics.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.navy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(auth.errorMessage ?? 'Invalid email or password.'),
        ),
      );
    }
  }

  // ── User Sign Up Submission (5 fields -> Admin Pending) ──
  Future<void> _handleUserSignUp() async {
    FocusScope.of(context).unfocus();
    if (!_userSignUpFormKey.currentState!.validate()) return;

    Haptics.light();
    final auth = context.read<AuthProvider>();
    final success = await auth.registerUser(
      name: _userNameController.text.trim(),
      email: _userEmailController.text.trim(),
      phone: _userPhoneController.text.trim(),
      password: _userPasswordController.text,
    );

    if (!mounted) return;

    if (success) {
      Haptics.success();
      final registeredEmail = _userEmailController.text.trim();
      _userNameController.clear();
      _userEmailController.clear();
      _userPhoneController.clear();
      _userPasswordController.clear();
      _userConfirmPasswordController.clear();

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.mark_email_read_rounded, color: AppColors.amber, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Registration Submitted',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registration submitted successfully. Your account is pending admin approval.',
                style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.navy),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slateFaint,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Text(
                  'The platform administrator will review your account in the Admin Panel before login access is activated.',
                  style: TextStyle(fontSize: 12, color: AppColors.slate),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _userMode = FormViewMode.signIn;
                  _signInEmailController.text = registeredEmail;
                  _signInPasswordController.clear();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Back to User Sign In'),
            ),
          ],
        ),
      );
    } else {
      Haptics.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(auth.errorMessage ?? 'Registration failed. Please try again.'),
        ),
      );
    }
  }

  // ── Transporter Sign Up Submission (7 fields -> Admin Pending) ──
  Future<void> _handleTransporterSignUp() async {
    FocusScope.of(context).unfocus();
    if (!_transporterSignUpFormKey.currentState!.validate()) return;

    Haptics.light();
    final auth = context.read<AuthProvider>();
    final success = await auth.registerTransporter(
      companyName: _transporterCompanyNameController.text.trim(),
      gstin: _transporterGstinController.text.trim(),
      transportId: _transporterTransportIdController.text.trim(),
      email: _transporterEmailController.text.trim(),
      phone: _transporterPhoneController.text.trim(),
      password: _transporterPasswordController.text,
    );

    if (!mounted) return;

    if (success) {
      Haptics.success();
      final registeredEmail = _transporterEmailController.text.trim();
      _transporterCompanyNameController.clear();
      _transporterGstinController.clear();
      _transporterTransportIdController.clear();
      _transporterEmailController.clear();
      _transporterPhoneController.clear();
      _transporterPasswordController.clear();
      _transporterConfirmPasswordController.clear();

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.mark_email_read_rounded, color: AppColors.emerald, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Registration Submitted',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registration submitted successfully. Your account is pending admin approval.',
                style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.navy),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slateFaint,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Text(
                  'An administrator will verify your company name, GSTIN, and Transport ID in the Admin Panel before access is granted.',
                  style: TextStyle(fontSize: 12, color: AppColors.slate),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _transporterMode = FormViewMode.signIn;
                  _signInEmailController.text = registeredEmail;
                  _signInPasswordController.clear();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Back to Transporter Sign In'),
            ),
          ],
        ),
      );
    } else {
      Haptics.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(auth.errorMessage ?? 'Registration failed. Please try again.'),
        ),
      );
    }
  }

  void _showPendingDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.hourglass_top_rounded, color: AppColors.amber, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Approval Pending',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your registration is still pending admin approval.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.slateFaint,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Text(
                'The platform administrator has not verified your credentials yet. Once accepted, you will be able to log in to your dashboard.',
                style: TextStyle(fontSize: 12.5, color: AppColors.slate),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
          ),
        ],
      ),
    );
  }

  void _showRejectedDialog(String? reason) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.roseAlert.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cancel_rounded, color: AppColors.roseAlert, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Registration Rejected',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your registration request was rejected. Please contact the administrator.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
            ),
            if (reason != null && reason.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.roseAlert.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.roseAlert.withValues(alpha: 0.25)),
                ),
                child: Text(
                  'Reason: $reason',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.roseAlert, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),

                  // Top Role Selector Gate
                  _buildRoleSelector(),
                  const SizedBox(height: 18),

                  // Active Role Authentication Form
                  _buildActiveRoleView(),
                  const SizedBox(height: 24),

                  _buildComplianceFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- 1. App Header ----------------

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _selectedRole.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _selectedRole.icon,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppConstants.appName,
          style: AppTextStyles.display.copyWith(
            color: AppColors.navy,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Enterprise Reverse Auction Platform',
          style: TextStyle(
            color: AppColors.slate,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ---------------- 2. Role Selector ----------------

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.slateLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: AuthRole.values.map((role) {
          final isSelected = role == _selectedRole;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onRoleChanged(role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.navy : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.navy.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      role.icon,
                      size: 14,
                      color: isSelected ? Colors.white : AppColors.slate,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        role.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.slate,
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------- 3. Active Role View Routing ----------------

  Widget _buildActiveRoleView() {
    switch (_selectedRole) {
      case AuthRole.user:
        return _userMode == FormViewMode.signIn
            ? _buildUserSignInCard()
            : _buildUserSignUpCard();
      case AuthRole.transporter:
        return _transporterMode == FormViewMode.signIn
            ? _buildTransporterSignInCard()
            : _buildTransporterSignUpCard();
      case AuthRole.admin:
        return _buildAdminSignInCard();
    }
  }

  // ===========================================================================
  // USER FLOW (FORMERLY SHIPPER)
  // ===========================================================================

  Widget _buildUserSignInCard() {
    return _buildCardContainer(
      child: Form(
        key: _signInFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(
              title: 'Sign in as User',
              subtitle: 'Access freight auctions, tenders & active loads',
              badge: 'USER',
              badgeColor: AppColors.electricBlue,
            ),
            const SizedBox(height: 18),

            // Email
            TextFormField(
              controller: _signInEmailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
              decoration: _inputDecoration(
                label: 'Email / Username',
                icon: Icons.alternate_email_rounded,
              ),
              validator: Validators.email,
            ),
            const SizedBox(height: 14),

            // Password
            TextFormField(
              controller: _signInPasswordController,
              obscureText: _obscureSignInPassword,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
              decoration: _inputDecoration(
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  icon: Icon(
                    _obscureSignInPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.slate,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscureSignInPassword = !_obscureSignInPassword),
                ),
              ),
              validator: Validators.password,
              onFieldSubmitted: (_) => _handleSignIn(),
            ),
            const SizedBox(height: 14),

            // Demo quick-fill chip
            _buildDemoQuickFill(
              label: 'Use User Demo Account',
              email: DemoConstants.userDemoEmail,
              password: DemoConstants.userDemoPassword,
            ),
            const SizedBox(height: 18),

            // Sign In Button
            _buildSubmitButton(
              label: 'Sign In as User',
              icon: Icons.login_rounded,
              color: AppColors.navy,
              onPressed: _handleSignIn,
            ),
            const SizedBox(height: 16),

            // Link ONLY to User Sign Up
            Center(
              child: TextButton(
                onPressed: () {
                  Haptics.selection();
                  setState(() => _userMode = FormViewMode.signUp);
                },
                child: RichText(
                  text: const TextSpan(
                    text: "Don't have a User account? ",
                    style: TextStyle(color: AppColors.slate, fontSize: 13, fontWeight: FontWeight.w500),
                    children: [
                      TextSpan(
                        text: 'Sign Up',
                        style: TextStyle(
                          color: AppColors.electricBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// User Sign Up Card - STRICTLY 5 FIELDS:
  /// 1. User Name
  /// 2. Email
  /// 3. Phone Number
  /// 4. Password
  /// 5. Confirm Password
  Widget _buildUserSignUpCard() {
    return _buildCardContainer(
      child: Form(
        key: _userSignUpFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.navy),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _userMode = FormViewMode.signIn),
                  tooltip: 'Back to User Sign In',
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Create User Account',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.electricBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'USER',
                    style: TextStyle(
                      color: AppColors.electricBlue,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Register your account to access reverse auctions & freight logistics',
              style: TextStyle(color: AppColors.slate, fontSize: 12),
            ),
            const SizedBox(height: 18),

            // 1. User Name (Full Name)
            TextFormField(
              controller: _userNameController,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
              decoration: _inputDecoration(
                label: 'User Name (Full Name)',
                icon: Icons.person_outline_rounded,
              ),
              validator: (v) {
                if ((v ?? '').trim().isEmpty) return 'User name is required.';
                if (v!.trim().length < 3) return 'Name must be at least 3 characters.';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // 2. Email Address
            TextFormField(
              controller: _userEmailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
              decoration: _inputDecoration(
                label: 'Email Address',
                icon: Icons.alternate_email_rounded,
              ),
              validator: Validators.email,
            ),
            const SizedBox(height: 12),

            // 3. Phone Number
            TextFormField(
              controller: _userPhoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
              decoration: _inputDecoration(
                label: 'Phone Number (10 digits)',
                icon: Icons.phone_android_rounded,
              ),
              validator: (v) {
                if ((v ?? '').trim().isEmpty) return 'Phone number is required.';
                return Validators.phone(v);
              },
            ),
            const SizedBox(height: 12),

            // 4. Password
            TextFormField(
              controller: _userPasswordController,
              obscureText: _obscureUserPassword,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
              decoration: _inputDecoration(
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  icon: Icon(
                    _obscureUserPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.slate,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscureUserPassword = !_obscureUserPassword),
                ),
              ),
              validator: Validators.password,
            ),
            const SizedBox(height: 12),

            // 5. Confirm Password
            TextFormField(
              controller: _userConfirmPasswordController,
              obscureText: _obscureUserConfirmPassword,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
              decoration: _inputDecoration(
                label: 'Confirm Password',
                icon: Icons.lock_reset_rounded,
                suffix: IconButton(
                  icon: Icon(
                    _obscureUserConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.slate,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscureUserConfirmPassword = !_obscureUserConfirmPassword),
                ),
              ),
              validator: (v) {
                if ((v ?? '').isEmpty) return 'Please confirm your password.';
                if (v != _userPasswordController.text) return 'Passwords do not match.';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Pending approval note
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_empty_rounded, size: 16, color: AppColors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Account will be submitted to Admin for approval before login is enabled.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.navy, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Submit Button
            _buildSubmitButton(
              label: 'Submit User Registration',
              icon: Icons.person_add_alt_1_rounded,
              color: AppColors.electricBlue,
              onPressed: _handleUserSignUp,
            ),
            const SizedBox(height: 14),

            Center(
              child: TextButton(
                onPressed: () => setState(() => _userMode = FormViewMode.signIn),
                child: RichText(
                  text: const TextSpan(
                    text: 'Already have a User account? ',
                    style: TextStyle(color: AppColors.slate, fontSize: 13, fontWeight: FontWeight.w500),
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                          color: AppColors.electricBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TRANSPORTER FLOW
  // ===========================================================================

  Widget _buildTransporterSignInCard() {
    return _buildCardContainer(
      child: Form(
        key: _signInFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(
              title: 'Sign in as Transporter',
              subtitle: 'Bid on live reverse auctions & manage contracts',
              badge: 'CARRIER',
              badgeColor: AppColors.emerald,
            ),
            const SizedBox(height: 18),

            // Email
            TextFormField(
              controller: _signInEmailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
              decoration: _inputDecoration(
                label: 'Email / Username',
                icon: Icons.alternate_email_rounded,
              ),
              validator: Validators.email,
            ),
            const SizedBox(height: 14),

            // Password
            TextFormField(
              controller: _signInPasswordController,
              obscureText: _obscureSignInPassword,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
              decoration: _inputDecoration(
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  icon: Icon(
                    _obscureSignInPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.slate,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscureSignInPassword = !_obscureSignInPassword),
                ),
              ),
              validator: Validators.password,
              onFieldSubmitted: (_) => _handleSignIn(),
            ),
            const SizedBox(height: 14),

            // Demo quick-fill chip
            _buildDemoQuickFill(
              label: 'Use Transporter Demo Account',
              email: DemoConstants.transporterDemoEmail,
              password: DemoConstants.transporterDemoPassword,
            ),
            const SizedBox(height: 18),

            // Sign In Button
            _buildSubmitButton(
              label: 'Sign In as Transporter',
              icon: Icons.login_rounded,
              color: AppColors.navy,
              onPressed: _handleSignIn,
            ),
            const SizedBox(height: 16),

            // Link ONLY to Transporter Sign Up
            Center(
              child: TextButton(
                onPressed: () {
                  Haptics.selection();
                  setState(() => _transporterMode = FormViewMode.signUp);
                },
                child: RichText(
                  text: const TextSpan(
                    text: "Don't have a Transporter account? ",
                    style: TextStyle(color: AppColors.slate, fontSize: 13, fontWeight: FontWeight.w500),
                    children: [
                      TextSpan(
                        text: 'Sign Up',
                        style: TextStyle(
                          color: AppColors.emerald,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Transporter Sign Up Card:
  /// Exactly 7 Fields, visually structured into 3 clear sections:
  /// Section 1: Company & Fleet Credentials (Company Name, GST Number, Transport ID)
  /// Section 2: Contact Details (Email, Phone)
  /// Section 3: Security Credentials (Password, Confirm Password)
  Widget _buildTransporterSignUpCard() {
    return _buildCardContainer(
      child: Form(
        key: _transporterSignUpFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.navy),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _transporterMode = FormViewMode.signIn),
                  tooltip: 'Back to Transporter Sign In',
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Create Transporter Account',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'CARRIER',
                    style: TextStyle(
                      color: AppColors.emerald,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Register your transport business for live reverse auction bidding',
              style: TextStyle(color: AppColors.slate, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // ════════ SECTION 1: Company & Fleet Credentials ════════
            _buildFormSectionHeader(
              step: '1',
              title: 'COMPANY & FLEET IDENTITY',
              icon: Icons.domain_verification_rounded,
            ),
            const SizedBox(height: 10),

            // 1. Transporter / Company Name
            TextFormField(
              controller: _transporterCompanyNameController,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
              decoration: _inputDecoration(
                label: 'Transporter / Company Name',
                icon: Icons.local_shipping_rounded,
              ),
              validator: (v) {
                if ((v ?? '').trim().isEmpty) return 'Company name is required.';
                return null;
              },
            ),
            const SizedBox(height: 10),

            // 2. GST Number (GSTIN)
            TextFormField(
              controller: _transporterGstinController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy, letterSpacing: 0.8),
              decoration: _inputDecoration(
                label: 'GST Number (GSTIN)',
                icon: Icons.receipt_long_rounded,
              ).copyWith(
                hintText: 'e.g. 27AAAAA0000A1Z5',
                hintStyle: const TextStyle(color: AppColors.slateLight, fontSize: 12),
              ),
              validator: (v) {
                final trimmed = (v ?? '').trim();
                if (trimmed.isEmpty) return 'GST number is required.';
                if (trimmed.length != 15) return 'GSTIN must be exactly 15 characters.';
                return null;
              },
            ),
            const SizedBox(height: 10),

            // 3. Transport ID / Vahan ID
            TextFormField(
              controller: _transporterTransportIdController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy, letterSpacing: 0.8),
              decoration: _inputDecoration(
                label: 'Transport ID / Vahan ID',
                icon: Icons.badge_outlined,
              ).copyWith(
                hintText: 'e.g. TR-MH-8842 / Vahan Fleet ID',
                hintStyle: const TextStyle(color: AppColors.slateLight, fontSize: 12),
              ),
              validator: (v) {
                if ((v ?? '').trim().isEmpty) return 'Transport ID / Vahan ID is required.';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ════════ SECTION 2: Contact Details ════════
            _buildFormSectionHeader(
              step: '2',
              title: 'CONTACT DETAILS',
              icon: Icons.contact_phone_outlined,
            ),
            const SizedBox(height: 10),

            // 4. Business Email
            TextFormField(
              controller: _transporterEmailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
              decoration: _inputDecoration(
                label: 'Business Email Address',
                icon: Icons.alternate_email_rounded,
              ),
              validator: Validators.email,
            ),
            const SizedBox(height: 10),

            // 5. Phone Number
            TextFormField(
              controller: _transporterPhoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
              decoration: _inputDecoration(
                label: 'Phone Number (10 digits)',
                icon: Icons.phone_android_rounded,
              ),
              validator: (v) {
                if ((v ?? '').trim().isEmpty) return 'Phone number is required.';
                return Validators.phone(v);
              },
            ),
            const SizedBox(height: 16),

            // ════════ SECTION 3: Security Credentials ════════
            _buildFormSectionHeader(
              step: '3',
              title: 'SECURITY CREDENTIALS',
              icon: Icons.lock_outline_rounded,
            ),
            const SizedBox(height: 10),

            // 6. Password
            TextFormField(
              controller: _transporterPasswordController,
              obscureText: _obscureTransporterPassword,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
              decoration: _inputDecoration(
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  icon: Icon(
                    _obscureTransporterPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.slate,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscureTransporterPassword = !_obscureTransporterPassword),
                ),
              ),
              validator: Validators.password,
            ),
            const SizedBox(height: 10),

            // 7. Confirm Password
            TextFormField(
              controller: _transporterConfirmPasswordController,
              obscureText: _obscureTransporterConfirmPassword,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
              decoration: _inputDecoration(
                label: 'Confirm Password',
                icon: Icons.lock_reset_rounded,
                suffix: IconButton(
                  icon: Icon(
                    _obscureTransporterConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.slate,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscureTransporterConfirmPassword = !_obscureTransporterConfirmPassword),
                ),
              ),
              validator: (v) {
                if ((v ?? '').isEmpty) return 'Please confirm your password.';
                if (v != _transporterPasswordController.text) return 'Passwords do not match.';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Pending approval note
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_empty_rounded, size: 16, color: AppColors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Carrier credentials, GSTIN & Transport ID will be verified by Admin in the Admin Panel before access.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.navy, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Submit Button
            _buildSubmitButton(
              label: 'Submit Transporter Registration',
              icon: Icons.local_shipping_rounded,
              color: AppColors.emerald,
              onPressed: _handleTransporterSignUp,
            ),
            const SizedBox(height: 14),

            Center(
              child: TextButton(
                onPressed: () => setState(() => _transporterMode = FormViewMode.signIn),
                child: RichText(
                  text: const TextSpan(
                    text: 'Already have a Transporter account? ',
                    style: TextStyle(color: AppColors.slate, fontSize: 13, fontWeight: FontWeight.w500),
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                          color: AppColors.emerald,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ADMIN FLOW (SIGN IN ONLY - STRICTLY NO SIGN UP)
  // ===========================================================================

  Widget _buildAdminSignInCard() {
    return _buildCardContainer(
      child: Form(
        key: _signInFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(
              title: 'Admin Sign In',
              subtitle: 'Platform administration & carrier verification gateway',
              badge: 'ADMIN',
              badgeColor: AppColors.navy,
            ),
            const SizedBox(height: 18),

            // Email
            TextFormField(
              controller: _signInEmailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
              decoration: _inputDecoration(
                label: 'Admin Email',
                icon: Icons.shield_outlined,
              ),
              validator: Validators.email,
            ),
            const SizedBox(height: 14),

            // Password
            TextFormField(
              controller: _signInPasswordController,
              obscureText: _obscureSignInPassword,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
              decoration: _inputDecoration(
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  icon: Icon(
                    _obscureSignInPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.slate,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscureSignInPassword = !_obscureSignInPassword),
                ),
              ),
              validator: Validators.password,
              onFieldSubmitted: (_) => _handleSignIn(),
            ),
            const SizedBox(height: 14),

            // Demo quick-fill chip
            _buildDemoQuickFill(
              label: 'Use Admin Demo Account',
              email: DemoConstants.adminDemoEmail,
              password: DemoConstants.adminDemoPassword,
            ),
            const SizedBox(height: 18),

            // Sign In Button
            _buildSubmitButton(
              label: 'Sign In as Admin',
              icon: Icons.admin_panel_settings_rounded,
              color: AppColors.navy,
              onPressed: _handleSignIn,
            ),
            const SizedBox(height: 14),

            // Admin info note (NO sign up option)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.slateLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 15, color: AppColors.slate),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Admin accounts are managed internally. Public registration is restricted.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.slate,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // COMMON WIDGET HELPERS
  // ===========================================================================

  Widget _buildFormSectionHeader({
    required String step,
    required String title,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.slateFaint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              step,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.emerald,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 14, color: AppColors.navy),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCardHeader({
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.slate, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            badge,
            style: TextStyle(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDemoQuickFill({
    required String label,
    required String email,
    required String password,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: () {
          Haptics.selection();
          setState(() {
            _signInEmailController.text = email;
            _signInPasswordController.text = password;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Demo credentials filled for $label ($email)'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.slateFaint,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flash_on_rounded, size: 13, color: AppColors.amber),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color color = AppColors.navy,
  }) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: auth.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 17, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.slate, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.slate, size: 18),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.slateFaint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.electricBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }

  // ---------------- 4. Compliance Footer ----------------

  Widget _buildComplianceFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_rounded, size: 14, color: AppColors.emerald),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              '256-bit Encrypted • Reverse Auction Procurement Gateway',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.slate,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
