import 'package:go_router/go_router.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/pending_approval_screen.dart';
import '../../screens/admin/admin_dashboard.dart';
import '../../screens/admin/pending_approvals_screen.dart';
import '../../screens/user/user_dashboard.dart';
import '../../screens/user/create_tender_screen.dart';
import '../../screens/user/draft_tenders_screen.dart';
import '../../screens/user/tender_review_screen.dart';
import '../../screens/user/tender_history_screen.dart';
import '../../screens/user/tender_monitor_screen.dart';
import '../../screens/transporter/transporter_dashboard.dart';
import '../../screens/transporter/tender_detail_screen.dart';
import '../../screens/transporter/auction_history_screen.dart';
import '../../screens/auction/stage1_auction_screen.dart';
import '../../screens/auction/stage_transition_screen.dart';
import '../../screens/auction/stage2_auction_screen.dart';
import '../../screens/auction/stage2_user_view_screen.dart';
import '../../screens/auction/result_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/splash'),
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/auth/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/auth/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/auth/pending', builder: (context, state) => const PendingApprovalScreen()),
    GoRoute(path: '/admin', builder: (context, state) => const AdminDashboard()),
    GoRoute(path: '/admin/pending', builder: (context, state) => const PendingApprovalsScreen()),
    GoRoute(path: '/user', builder: (context, state) => const UserDashboard()),
    GoRoute(path: '/user/create-tender', builder: (context, state) => const CreateTenderScreen()),
    GoRoute(path: '/user/drafts', builder: (context, state) => const DraftTendersScreen()),
    GoRoute(path: '/user/history', builder: (context, state) => const TenderHistoryScreen()),
    GoRoute(path: '/user/tender/:id/review', builder: (context, state) => TenderReviewScreen(tenderId: int.parse(state.pathParameters['id']!))),
    GoRoute(path: '/user/tender/:id/monitor', builder: (context, state) => TenderMonitorScreen(tenderId: int.parse(state.pathParameters['id']!))),
    GoRoute(path: '/transporter', builder: (context, state) => const TransporterDashboard()),
    GoRoute(path: '/transporter/tender/:id', builder: (context, state) => TenderDetailScreen(tenderId: int.parse(state.pathParameters['id']!))),
    GoRoute(path: '/transporter/history', builder: (context, state) => const AuctionHistoryScreen()),
    GoRoute(path: '/auction/:tenderId/stage1', builder: (context, state) => Stage1AuctionScreen(tenderId: int.parse(state.pathParameters['tenderId']!))),
    GoRoute(path: '/auction/:tenderId/transition', builder: (context, state) => StageTransitionScreen(tenderId: int.parse(state.pathParameters['tenderId']!))),
    GoRoute(path: '/auction/:tenderId/stage2', builder: (context, state) => Stage2AuctionScreen(tenderId: int.parse(state.pathParameters['tenderId']!))),
    GoRoute(path: '/auction/:tenderId/stage2-user', builder: (context, state) => Stage2UserViewScreen(tenderId: int.parse(state.pathParameters['tenderId']!))),
    GoRoute(path: '/auction/:tenderId/result', builder: (context, state) => ResultScreen(tenderId: int.parse(state.pathParameters['tenderId']!))),
  ],
);