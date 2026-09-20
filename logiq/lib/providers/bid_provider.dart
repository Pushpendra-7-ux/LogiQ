import 'package:flutter/foundation.dart';
import 'package:logiq/models/auction.dart';
import 'package:logiq/models/bid.dart';
import 'package:logiq/services/auction_service.dart';

class BidProvider extends ChangeNotifier {
  final AuctionService _auctionService = AuctionService.instance;

  BidProvider();

  List<Bid> _myBids = [];
  final Map<int, Auction> _auctionCache = {};
  bool isLoading = false;

  List<Bid> get myBids => _myBids;

  List<Bid> get wonBids => _myBids.where((b) {
        final a = _auctionCache[b.auctionId];
        return a != null &&
            a.status == AuctionStatus.completed &&
            a.winnerTransporterId == b.transporterId;
      }).toList();

  List<Bid> get activeBids => _myBids.where((b) {
        final a = _auctionCache[b.auctionId];
        return a == null || a.status.isRunning;
      }).toList();

  List<Bid> get lostBids => _myBids.where((b) {
        final a = _auctionCache[b.auctionId];
        return a != null &&
            a.status == AuctionStatus.completed &&
            a.winnerTransporterId != null &&
            a.winnerTransporterId != b.transporterId;
      }).toList();

  Future<void> loadBidsForTransporter(int transporterId) async {
    isLoading = true;
    notifyListeners();

    try {
      _myBids = await _auctionService.getBidsByTransporter(transporterId);

      // Cache related auctions for status determination
      for (final bid in _myBids) {
        if (!_auctionCache.containsKey(bid.auctionId)) {
          final auction = await _auctionService.getAuctionById(bid.auctionId);
          if (auction != null) {
            _auctionCache[bid.auctionId] = auction;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading bids for transporter: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> hasBidOnTender(int tenderId, int transporterId) async {
    final bids = await _auctionService.getBidsByTransporter(transporterId);
    return bids.any((b) => b.tenderId == tenderId);
  }

  Future<int> bidCountForTender(int tenderId) async {
    final auction = await _auctionService.getAuctionByTenderId(tenderId);
    if (auction == null || auction.id == null) return 0;

    final bids = await _auctionService.getValidStageBids(auction.id!, auction.currentStage);
    return bids.length;
  }

  Future<Bid?> myLatestBid(int auctionId, int transporterId, int stage) async {
    return await _auctionService.getLatestBidFor(
      auctionId: auctionId,
      transporterId: transporterId,
      stage: stage,
    );
  }
}
