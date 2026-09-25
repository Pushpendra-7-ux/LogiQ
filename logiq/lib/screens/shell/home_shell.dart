import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/providers/tender_provider.dart';
import 'package:logiq/core/theme/app_colors.dart';

class HomeShell extends StatefulWidget {
  final Widget child;

  const HomeShell({super.key, required this.child});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  DateTime? _lastBackPressTime;
  Timer? _autoTicker;

  @override
  void initState() {
    super.initState();
    _autoTicker = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;
      final role = user?.role;
      final tid = auth.currentTransporter?.id ?? user?.id;
      context.read<TenderProvider>().checkAutoPublish(user?.id, role, tid);
    });
  }

  @override
  void dispose() {
    _autoTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final location = GoRouterState.of(context).matchedLocation;

    final isUser = auth.isUser;
    final isAdmin = auth.isAdmin;

    final destinations = isUser
        ? _userTabs
        : isAdmin
            ? _adminTabs
            : _transporterTabs;
    final selectedColor = isUser ? AppColors.logiqGreen : AppColors.logiqGreen;

    int selectedIndex = 0;
    for (int i = 0; i < destinations.length; i++) {
      if (location == destinations[i].route) {
        selectedIndex = i;
        break;
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }

        if (location != '/home') {
          context.go('/home');
          return;
        }

        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Press back again to exit',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppColors.navy,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 80),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: List.generate(destinations.length, (index) {
                  final item = destinations[index];
                  final isSelected = selectedIndex == index;
                  return Expanded(
                    child: InkWell(
                      onTap: () => context.go(item.route),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSelected ? item.activeIcon : item.icon,
                            size: 24,
                            color: isSelected ? selectedColor : AppColors.slate,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? selectedColor : AppColors.slate,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _userTabs = <_NavItem>[
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      route: '/home',
    ),
    _NavItem(
      icon: Icons.add_circle_outline,
      activeIcon: Icons.add_circle,
      label: 'Create',
      route: '/tender/create',
    ),
    _NavItem(
      icon: Icons.show_chart_rounded,
      activeIcon: Icons.show_chart_rounded,
      label: 'Live Bids',
      route: '/active-tenders',
    ),
    _NavItem(
      icon: Icons.history_outlined,
      activeIcon: Icons.history_rounded,
      label: 'History',
      route: '/tender/history',
    ),
  ];

  static const _adminTabs = <_NavItem>[
    _NavItem(
      icon: Icons.grid_view_rounded,
      activeIcon: Icons.grid_view_rounded,
      label: 'Dashboard',
      route: '/home',
    ),
    _NavItem(
      icon: Icons.how_to_reg_outlined,
      activeIcon: Icons.how_to_reg,
      label: 'Approvals',
      route: '/admin/approvals',
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Tenders',
      route: '/admin/tenders',
    ),
    _NavItem(
      icon: Icons.manage_accounts_outlined,
      activeIcon: Icons.manage_accounts_rounded,
      label: 'Settings',
      route: '/profile',
    ),
  ];

  static const _transporterTabs = <_NavItem>[
    _NavItem(
      icon: Icons.grid_view_rounded,
      activeIcon: Icons.grid_view_rounded,
      label: 'Dashboard',
      route: '/home',
    ),
    _NavItem(
      icon: Icons.local_shipping_outlined,
      activeIcon: Icons.local_shipping_rounded,
      label: 'Available',
      route: '/transporter/available',
    ),
    _NavItem(
      icon: Icons.gavel_outlined,
      activeIcon: Icons.gavel_rounded,
      label: 'My Bids',
      route: '/bids',
    ),
    _NavItem(
      icon: Icons.manage_accounts_outlined,
      activeIcon: Icons.manage_accounts_rounded,
      label: 'Settings',
      route: '/profile',
    ),
  ];
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
