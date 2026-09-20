import 'package:logiq/data/local/local_auction_data_source.dart';
import 'package:logiq/data/local/local_tender_data_source.dart';
import 'package:logiq/data/local/local_user_data_source.dart';
import 'package:logiq/models/auction.dart';
import 'package:logiq/models/material.dart';
import 'package:logiq/models/tender.dart';
import 'package:logiq/models/transporter.dart';

/// Service layer abstraction for Tender management and draft workflows.
/// Providers communicate with this service instead of LocalTenderDataSource directly.
/// When REST APIs arrive, only this service will be updated to use DioClient.
class TenderService {
  TenderService._();
  static final TenderService instance = TenderService._();

  final LocalTenderDataSource _tenderDataSource = LocalTenderDataSource.instance;
  final LocalUserDataSource _userDataSource = LocalUserDataSource.instance;
  final LocalAuctionDataSource _auctionDataSource = LocalAuctionDataSource.instance;

  Future<List<Transporter>> getApprovedTransporters() async {
    return await _userDataSource.allCompanies(approvedOnly: true);
  }

  Future<List<Tender>> getTendersForUser(int userId, {List<TenderStatus>? statuses}) async {
    return await _tenderDataSource.byCreator(userId, statuses: statuses);
  }

  Future<List<Tender>> getTendersForTransporter(int transporterId) async {
    return await _tenderDataSource.forTransporter(transporterId);
  }

  Future<List<Tender>> getAllTenders() async {
    return await _tenderDataSource.all();
  }

  Future<Tender?> getTenderById(int id) async {
    return await _tenderDataSource.byId(id);
  }

  Future<List<MaterialItem>> getMaterials(int tenderId) async {
    return await _tenderDataSource.materials(tenderId);
  }

  Future<List<int>> getParticipantIds(int tenderId) async {
    return await _tenderDataSource.participantIds(tenderId);
  }

  Future<int> getParticipantCount(int tenderId) async {
    return await _tenderDataSource.participantCount(tenderId);
  }

  Future<List<Tender>> getHistory({int? creatorId, int? transporterId}) async {
    return await _tenderDataSource.history(creatorId: creatorId, transporterId: transporterId);
  }

  Future<int> createTender({
    required Tender tender,
    required List<MaterialItem> materials,
    required List<int> transporterIds,
    Map<String, Object?>? auction,
  }) async {
    return await _tenderDataSource.insert(
      tender: tender,
      materials: materials,
      transporterIds: transporterIds,
      auction: auction,
    );
  }

  Future<void> updateDraft({
    required int tenderId,
    required Tender tender,
    required List<MaterialItem> materials,
    required List<int> transporterIds,
  }) async {
    await _tenderDataSource.updateDraft(
      tenderId: tenderId,
      tender: tender,
      materials: materials,
      transporterIds: transporterIds,
    );
  }

  Future<void> setStatus(int tenderId, TenderStatus status) async {
    await _tenderDataSource.setStatus(tenderId, status);
  }

  Future<void> deleteDraft(int tenderId) async {
    await _tenderDataSource.deleteDraft(tenderId);
  }

  /// Create an auction record for a just-published tender.
  Future<void> createAuctionForTender({
    required int tenderId,
    required DateTime biddingStart,
    required DateTime softEnd,
    required DateTime hardStop,
  }) async {
    final auction = Auction(
      tenderId: tenderId,
      currentStage: 1,
      stage1Start: biddingStart,
      stage1End: softEnd,
      stage2Start: softEnd,
      stage2End: hardStop,
      status: AuctionStatus.scheduled,
    );
    await _auctionDataSource.save(auction);

    // Sync participants from tender_participants to auction_participants
    final participantIds = await _tenderDataSource.participantIds(tenderId);
    final savedAuction = await _auctionDataSource.byTenderId(tenderId);
    if (savedAuction?.id != null) {
      await _auctionDataSource.syncParticipants(savedAuction!.id!, participantIds);
    }
  }
}
