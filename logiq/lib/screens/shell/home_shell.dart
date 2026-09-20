import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/core/theme/app_colors.dart';

class HomeShell extends StatelessWidget {
  final Widget child;

  const HomeShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final location = GoRouterState.of(context).matchedLocation;

    final isUser = auth.isUser;
    final isAdmin = auth.isAdmin;
    final isTransporter = auth.isTransporter;

    final destinations = isUser ? _userTabs : _otherTabs(isAdmin, isTransporter);
    final selectedColor = isUser ? AppColors.logiqGreen : AppColors.electricBlue;

    int selectedIndex = 0;
    for (int i = 0; i < destinations.length; i++) {
      if (location == destinations[i].route) {
        selectedIndex = i;
        break;
      }
    }

    return Scaffold(
      body: child,
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

  static List<_NavItem> _otherTabs(bool isAdmin, bool isTransporter) => [
        const _NavItem(
          icon: Icons.grid_view_rounded,
          activeIcon: Icons.grid_view_rounded,
          label: 'Dashboard',
          route: '/home',
        ),
        _NavItem(
          icon: Icons.receipt_long_rounded,
          activeIcon: Icons.receipt_long_rounded,
          label: 'Tenders',
          route: isAdmin ? '/admin/tenders' : '/transporter/available',
        ),
        _NavItem(
          icon: Icons.local_shipping_rounded,
          activeIcon: Icons.local_shipping_rounded,
          label: 'Live Loads',
          route: isTransporter ? '/bids' : '/admin/users',
        ),
        const _NavItem(
          icon: Icons.manage_accounts_rounded,
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
