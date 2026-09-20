import 'package:logiq/data/local/local_auction_data_source.dart';
import 'package:logiq/data/local/local_bid_data_source.dart';
import 'package:logiq/data/local/local_user_data_source.dart';
import 'package:logiq/models/auction.dart';
import 'package:logiq/models/auction_participant.dart';
import 'package:logiq/models/auction_result.dart';
import 'package:logiq/models/bid.dart';

/// Service layer abstraction for Auctions and Bidding.
/// Providers communicate with this service instead of LocalAuctionDataSource / LocalBidDataSource.
/// When REST APIs arrive, only this service will be updated to use DioClient.
class AuctionService {
  AuctionService._();
  static final AuctionService instance = AuctionService._();

  final LocalAuctionDataSource _auctionDataSource = LocalAuctionDataSource.instance;
  final LocalBidDataSource _bidDataSource = LocalBidDataSource.instance;
  final LocalUserDataSource _userDataSource = LocalUserDataSource.instance;

  Future<Auction?> getAuctionByTenderId(int tenderId) async {
    return await _auctionDataSource.byTenderId(tenderId);
  }

  Future<Auction?> getAuctionById(int id) async {
    return await _auctionDataSource.byId(id);
  }

  Future<List<Auction>> getAllAuctions() async {
    return await _auctionDataSource.all();
  }

  Future<List<Auction>> getRunningAuctions() async {
    return await _auctionDataSource.running();
  }

  Future<void> saveAuction(Auction auction) async {
    await _auctionDataSource.save(auction);
  }

  Future<void> syncParticipants(int auctionId, List<int> transporterIds) async {
    await _auctionDataSource.syncParticipants(auctionId, transporterIds);
  }

  Future<void> markStage1Results(int auctionId, {required List<int> qualifiedTransporterIds}) async {
    await _auctionDataSource.markStage1Results(
      auctionId,
      qualifiedTransporterIds: qualifiedTransporterIds,
    );
  }

  Future<List<AuctionParticipant>> getParticipants(int auctionId) async {
    return await _auctionDataSource.participants(auctionId);
  }

  Future<List<AuctionParticipant>> getQualifiedParticipants(int auctionId) async {
    return await _auctionDataSource.qualified(auctionId);
  }

  Future<void> saveResult(AuctionResult result) async {
    await _auctionDataSource.saveResult(result);
  }

  Future<AuctionResult?> getResultByAuction(int auctionId) async {
    return await _auctionDataSource.resultByAuction(auctionId);
  }

  Future<AuctionResult?> getResultByTender(int tenderId) async {
    return await _auctionDataSource.resultByTender(tenderId);
  }

  Future<int> countAuctionsByStatus(List<String> statuses) async {
    return await _auctionDataSource.countByStatus(statuses);
  }

  // ---------- Bid operations ----------

  Future<Bid> insertBid({
    required int auctionId,
    required int tenderId,
    required int transporterId,
    required double amount,
    required int stage,
  }) async {
    return await _bidDataSource.insert(
      auctionId: auctionId,
      tenderId: tenderId,
      transporterId: transporterId,
      amount: amount,
      stage: stage,
    );
  }

  Future<void> invalidatePreviousBids({
    required int auctionId,
    required int transporterId,
    required int stage,
  }) async {
    await _bidDataSource.invalidatePrevious(
      auctionId: auctionId,
      transporterId: transporterId,
      stage: stage,
    );
  }

  Future<List<Bid>> getValidStageBids(int auctionId, int stage) async {
    return await _bidDataSource.validStageBids(auctionId, stage);
  }

  Future<List<Bid>> getAllValidBids(int auctionId) async {
    return await _bidDataSource.allValidBids(auctionId);
  }

  Future<List<Bid>> getBidsByTransporter(int transporterId) async {
    return await _bidDataSource.bidsByTransporter(transporterId);
  }

  Future<Bid?> getLatestBidFor({
    required int auctionId,
    required int transporterId,
    required int stage,
  }) async {
    return await _bidDataSource.latestBidFor(
      auctionId: auctionId,
      transporterId: transporterId,
      stage: stage,
    );
  }

  Future<Map<int, String>> getCompanyNames(List<int> transporterIds) async {
    return await _userDataSource.companyNamesByIds(transporterIds);
  }
}
