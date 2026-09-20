/// REST API skeleton — NOT used by the prototype.
///
/// When the company hands over its REST API:
///   1. implement these methods with DioClient().dio,
///   2. create ApiTenderDataSource / ApiAuctionDataSource etc. mirroring the
///      local data sources,
///   3. point the services/ layer at them.
/// Screens, providers, models and UI remain untouched.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  // Future<List<Tender>> fetchTenders({String? status}) => throw UnimplementedError();
  // Future<Tender> createTender(Map<String, Object?> body) => throw UnimplementedError();
  // Future<Auction> fetchAuction(int tenderId) => throw UnimplementedError();
  // Future<Bid> submitBid(int tenderId, double amount, int stage) => throw UnimplementedError();
  // Future<List<RankingEntry>> fetchRanking(int tenderId) => throw UnimplementedError();
  // Future<AuctionResult> fetchResult(int tenderId) => throw UnimplementedError();
}
