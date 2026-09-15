class ApiEndpoints {
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  static const String pendingUsers = '/admin/pending-users';
  static const String approve = '/admin/approve';
  static const String reject = '/admin/reject';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminTransporters = '/admin/transporters';

  static const String tenders = '/tenders';
  static const String draftTenders = '/tenders/drafts/list';
  static const String tenderHistory = '/tenders/history/list';
  static const String approvedTransporters = '/tenders/transporters/approved';

  static String tenderById(int id) => '/tenders/$id';
  static String publishTender(int id) => '/tenders/$id/publish';
  static String tenderParticipants(int id) => '/tenders/$id/participants';

  static String startStage1(int id) => '/auctions/$id/start-stage1';
  static String auctionStatus(int id) => '/auctions/$id/status';
  static String submitBid(int id) => '/auctions/$id/bids';
  static String ranking(int id) => '/auctions/$id/ranking';
  static String completeStage1(int id) => '/auctions/$id/complete-stage1';
  static String startStage2(int id) => '/auctions/$id/start-stage2';
  static String completeStage2(int id) => '/auctions/$id/complete-stage2';
  static String auctionResult(int id) => '/auctions/$id/result';

  static String wsAuction(int tenderId, String token) =>
      '/ws/auction/$tenderId?token=$token';
}