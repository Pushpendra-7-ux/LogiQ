import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:logiq/core/router/route_transitions.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/models/tender.dart';
import 'package:logiq/screens/splash/splash_screen.dart';
import 'package:logiq/screens/auth/login_screen.dart';
import 'package:logiq/screens/shell/home_shell.dart';
import 'package:logiq/screens/user/user_home_screen.dart';
import 'package:logiq/screens/user/create_tender_screen.dart';
import 'package:logiq/screens/user/tender_detail_user_screen.dart';
import 'package:logiq/screens/user/drafts_screen.dart';
import 'package:logiq/screens/user/tender_history_screen.dart';
import 'package:logiq/screens/user/active_tenders_user_screen.dart';
import 'package:logiq/screens/user/transporter_selection_screen.dart';
import 'package:logiq/screens/transporter/transporter_home_screen.dart';
import 'package:logiq/screens/transporter/tender_detail_transporter_screen.dart';
import 'package:logiq/screens/transporter/place_bid_screen.dart';
import 'package:logiq/screens/transporter/stage2_live_screen.dart';
import 'package:logiq/screens/transporter/my_bids_screen.dart';
import 'package:logiq/screens/transporter/bid_result_screen.dart';
import 'package:logiq/screens/transporter/available_tenders_screen.dart';
import 'package:logiq/screens/transporter/active_auctions_screen.dart';
import 'package:logiq/screens/admin/admin_home_screen.dart';
import 'package:logiq/screens/admin/admin_tenders_screen.dart';
import 'package:logiq/screens/admin/admin_users_screen.dart';
import 'package:logiq/screens/admin/admin_approvals_screen.dart';
import 'package:logiq/screens/admin/admin_transporters_screen.dart';
import 'package:logiq/screens/profile/profile_screen.dart';

GoRouter buildRouter(BuildContext context) {
  final auth = context.read<AuthProvider>();

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = context.read<AuthProvider>().isLoggedIn;
      final isSplash = state.matchedLocation == '/splash';
      final isLogin = state.matchedLocation == '/login';
      if (isSplash) return null;
      if (!loggedIn && !isLogin) return '/login';
      if (loggedIn && isLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionDuration: RouteTransitions.duration,
          transitionsBuilder: RouteTransitions.fadeScale,
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionDuration: RouteTransitions.duration,
          transitionsBuilder: RouteTransitions.fadeScale,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) {
              final auth = context.read<AuthProvider>();
              Widget screen;
              if (auth.isAdmin) {
                screen = const AdminHomeScreen();
              } else if (auth.isTransporter) {
                screen = const TransporterHomeScreen();
              } else {
                screen = const UserHomeScreen();
              }
              return CustomTransitionPage(
                key: state.pageKey,
                child: screen,
                transitionDuration: RouteTransitions.durationFast,
                transitionsBuilder: RouteTransitions.fadeScale,
              );
            },
          ),
          GoRoute(
            path: '/tender/create',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: CreateTenderScreen(editingTender: state.extra as Tender?),
              transitionDuration: RouteTransitions.durationFast,
              transitionsBuilder: RouteTransitions.fadeScale,
            ),
          ),
          GoRoute(
            path: '/active-tenders',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ActiveTendersUserScreen(),
              transitionDuration: RouteTransitions.durationFast,
              transitionsBuilder: RouteTransitions.fadeScale,
            ),
          ),
          GoRoute(
            path: '/tender/history',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const TenderHistoryScreen(),
              transitionDuration: RouteTransitions.durationFast,
              transitionsBuilder: RouteTransitions.fadeScale,
            ),
          ),
          GoRoute(
            path: '/bids',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const MyBidsScreen(),
              transitionDuration: RouteTransitions.durationFast,
              transitionsBuilder: RouteTransitions.fadeScale,
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
              transitionDuration: RouteTransitions.durationFast,
              transitionsBuilder: RouteTransitions.fadeScale,
            ),
          ),
          GoRoute(
            path: '/admin/tenders',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AdminTendersScreen(),
              transitionDuration: RouteTransitions.durationFast,
              transitionsBuilder: RouteTransitions.fadeScale,
            ),
          ),
          GoRoute(
            path: '/admin/approvals',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AdminApprovalsScreen(),
              transitionDuration: RouteTransitions.durationFast,
              transitionsBuilder: RouteTransitions.fadeScale,
            ),
          ),
          GoRoute(
            path: '/admin/transporters',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AdminTransportersScreen(),
              transitionDuration: RouteTransitions.durationFast,
              transitionsBuilder: RouteTransitions.fadeScale,
            ),
          ),
          GoRoute(
            path: '/admin/users',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AdminUsersScreen(),
              transitionDuration: RouteTransitions.durationFast,
              transitionsBuilder: RouteTransitions.fadeScale,
            ),
          ),
          GoRoute(
            path: '/transporter/available',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AvailableTendersScreen(),
              transitionDuration: RouteTransitions.durationFast,
              transitionsBuilder: RouteTransitions.fadeScale,
            ),
          ),
          GoRoute(
            path: '/transporter/auctions',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ActiveAuctionsScreen(),
              transitionDuration: RouteTransitions.durationFast,
              transitionsBuilder: RouteTransitions.fadeScale,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/drafts',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DraftsScreen(),
          transitionDuration: RouteTransitions.duration,
          transitionsBuilder: RouteTransitions.slideUp,
        ),
      ),
      GoRoute(
        path: '/tender/edit',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: ValueKey('edit_${(state.extra as Tender?)?.id ?? UniqueKey()}'),
          child: CreateTenderScreen(
            key: ValueKey('create_tender_${(state.extra as Tender?)?.id ?? "new"}'),
            editingTender: state.extra as Tender?,
          ),
          transitionDuration: RouteTransitions.duration,
          transitionsBuilder: RouteTransitions.slideUp,
        ),
      ),
      GoRoute(
        path: '/transporter-selection',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const TransporterSelectionScreen(),
          transitionDuration: RouteTransitions.duration,
          transitionsBuilder: RouteTransitions.slideUp,
        ),
      ),
      GoRoute(
        path: '/tender/:id',
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          final auth = context.read<AuthProvider>();
          final screen = auth.isTransporter
              ? TenderDetailTransporterScreen(tenderId: id)
              : TenderDetailUserScreen(tenderId: id);
          return CustomTransitionPage(
            key: state.pageKey,
            child: screen,
            transitionDuration: RouteTransitions.duration,
            transitionsBuilder: RouteTransitions.slideUp,
          );
        },
        routes: [
          GoRoute(
            path: 'bid',
            pageBuilder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return CustomTransitionPage(
                key: state.pageKey,
                child: PlaceBidScreen(tenderId: id),
                transitionDuration: RouteTransitions.duration,
                transitionsBuilder: RouteTransitions.slideUp,
              );
            },
          ),
          GoRoute(
            path: 'live',
            pageBuilder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return CustomTransitionPage(
                key: state.pageKey,
                child: Stage2LiveScreen(tenderId: id),
                transitionDuration: RouteTransitions.duration,
                transitionsBuilder: RouteTransitions.fadeScale,
              );
            },
          ),
          GoRoute(
            path: 'result',
            pageBuilder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return CustomTransitionPage(
                key: state.pageKey,
                child: BidResultScreen(tenderId: id),
                transitionDuration: RouteTransitions.duration,
                transitionsBuilder: RouteTransitions.fadeScale,
              );
            },
          ),
        ],
      ),
    ],
  );
}
