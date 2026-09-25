import 'package:logiq/data/local/local_auction_data_source.dart';
import 'package:logiq/data/local/local_bid_data_source.dart';
import 'package:logiq/data/local/local_tender_data_source.dart';
import 'package:logiq/data/local/local_user_data_source.dart';
import 'package:logiq/models/auction.dart';
import 'package:logiq/models/auction_participant.dart';
import 'package:logiq/models/auction_result.dart';
import 'package:logiq/models/bid.dart';
import 'package:logiq/models/tender.dart';

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

  Future<void> startStage2ForTender({
    required int tenderId,
    Duration stage2Duration = const Duration(minutes: 2),
  }) async {
    final auction = await _auctionDataSource.byTenderId(tenderId);
    if (auction == null || auction.id == null) return;

    final stage1Bids = await _bidDataSource.validStageBids(auction.id!, 1);
    stage1Bids.sort((a, b) => a.amount.compareTo(b.amount));
    final seen = <int>{};
    final top5 = <int>[];
    for (final b in stage1Bids) {
      if (seen.add(b.transporterId)) {
        top5.add(b.transporterId);
        if (top5.length == 5) break;
      }
    }

    if (top5.isNotEmpty) {
      await _auctionDataSource.markStage1Results(auction.id!, qualifiedTransporterIds: top5);
    }

    final now = DateTime.now();
    final updated = auction.copyWith(
      currentStage: 2,
      status: AuctionStatus.stage2Live,
      stage2Start: now,
      stage2End: now.add(stage2Duration),
    );
    await _auctionDataSource.save(updated);
    await LocalTenderDataSource.instance.setStatus(tenderId, TenderStatus.stage2);
  }

  Future<void> checkAndTransitionAuction(int tenderId) async {
    final auction = await _auctionDataSource.byTenderId(tenderId);
    if (auction == null || auction.id == null) return;

    final now = DateTime.now();
    if (auction.status == AuctionStatus.scheduled && now.isAfter(auction.stage1Start)) {
      final updated = auction.copyWith(status: AuctionStatus.stage1Live, currentStage: 1);
      await _auctionDataSource.save(updated);
      await LocalTenderDataSource.instance.setStatus(tenderId, TenderStatus.stage1);
    } else if (auction.status == AuctionStatus.stage1Live && now.isAfter(auction.stage1End)) {
      final updated = auction.copyWith(status: AuctionStatus.stage1Completed);
      await _auctionDataSource.save(updated);
      final stage1Bids = await _bidDataSource.validStageBids(auction.id!, 1);
      stage1Bids.sort((a, b) => a.amount.compareTo(b.amount));
      final seen = <int>{};
      final top5 = <int>[];
      for (final b in stage1Bids) {
        if (seen.add(b.transporterId)) {
          top5.add(b.transporterId);
          if (top5.length == 5) break;
        }
      }
      if (top5.isNotEmpty) {
        await _auctionDataSource.markStage1Results(auction.id!, qualifiedTransporterIds: top5);
      }
    } else if (auction.status == AuctionStatus.stage2Live && now.isAfter(auction.stage2End)) {
      final stage2Bids = await _bidDataSource.validStageBids(auction.id!, 2);
      stage2Bids.sort((a, b) => a.amount.compareTo(b.amount));
      Bid? winningBid;
      if (stage2Bids.isNotEmpty) {
        winningBid = stage2Bids.first;
      } else {
        final stage1Bids = await _bidDataSource.validStageBids(auction.id!, 1);
        stage1Bids.sort((a, b) => a.amount.compareTo(b.amount));
        if (stage1Bids.isNotEmpty) {
          winningBid = stage1Bids.first;
        }
      }

      if (winningBid != null) {
        final names = await _userDataSource.companyNamesByIds([winningBid.transporterId]);
        final winnerName = names[winningBid.transporterId] ?? 'Carrier ${winningBid.transporterId}';
        final result = AuctionResult(
          auctionId: auction.id!,
          winnerTransporterId: winningBid.transporterId,
          winnerName: winnerName,
          winningBid: winningBid.amount,
          completedAt: now,
        );
        await _auctionDataSource.saveResult(result);
        final completedAuction = auction.copyWith(
          status: AuctionStatus.completed,
          winnerTransporterId: () => winningBid!.transporterId,
          finalPrice: () => winningBid!.amount,
        );
        await _auctionDataSource.save(completedAuction);
        await LocalTenderDataSource.instance.setStatus(tenderId, TenderStatus.completed);
      }
    }
  }
}
