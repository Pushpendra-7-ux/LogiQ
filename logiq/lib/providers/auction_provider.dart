import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:logiq/models/auction.dart';
import 'package:logiq/models/tender.dart';
import 'package:logiq/models/bid.dart';
import 'package:logiq/models/auction_result.dart';
import 'package:logiq/services/auction_service.dart';
import 'package:logiq/services/tender_service.dart';
import 'package:logiq/core/constants/demo_constants.dart';

class AuctionProvider extends ChangeNotifier {
  final AuctionService _auctionService = AuctionService.instance;
  final TenderService _tenderService = TenderService.instance;

  Auction? currentAuction;
  Tender? currentTender;
  int secondsRemaining = 0;
  List<RankingEntry> rankings = [];
  Timer? _ticker;
  Timer? _competitorTimer;
  bool isFinalized = false;
  bool _isDisposed = false;

  int? winnerTransporterId;
  double? winningBid;
  String? winnerName;

  bool get isLoading => currentAuction == null || currentTender == null;
  bool get isBlindStage2 => currentAuction?.currentStage == 2;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> loadAuction(int tenderId) async {
    isFinalized = false;
    winnerTransporterId = null;
    winningBid = null;
    winnerName = null;

    currentTender = await _tenderService.getTenderById(tenderId);
    currentAuction = await _auctionService.getAuctionByTenderId(tenderId);

    if (currentAuction?.id != null) {
      await _refreshRankings(currentAuction!.id!, currentAuction!.currentStage);
    }

    if (currentAuction?.status == AuctionStatus.completed && currentAuction?.id != null) {
      final result = await _auctionService.getResultByAuction(currentAuction!.id!);
      if (result != null) {
        winnerTransporterId = result.winnerTransporterId;
        winningBid = result.winningBid;
        winnerName = result.winnerName;
        isFinalized = true;
      }
    }
    notifyListeners();
  }

  Future<void> startStage1() async {
    if (currentAuction == null) return;

    final now = DateTime.now();
    final diff = currentTender != null
        ? currentTender!.softEnd.difference(currentTender!.biddingStart)
        : DemoConstants.stage1Duration;
    final dur = diff.inSeconds > 0 ? diff : const Duration(minutes: 3);
    currentAuction = currentAuction!.copyWith(
      status: AuctionStatus.stage1Live,
      currentStage: 1,
      stage1Start: now,
      stage1End: now.add(dur),
    );
    await _auctionService.saveAuction(currentAuction!);

    secondsRemaining = dur.inSeconds;

    _startTicker();
    _startCompetitorSimulation(1);

    notifyListeners();
  }

  Future<void> startStage2(int transporterId) async {
    if (currentAuction == null) return;

    final now = DateTime.now();
    currentAuction = currentAuction!.copyWith(
      status: AuctionStatus.stage2Live,
      currentStage: 2,
      stage2Start: now,
      stage2End: now.add(DemoConstants.stage2Duration),
    );
    await _auctionService.saveAuction(currentAuction!);

    secondsRemaining = DemoConstants.stage2Duration.inSeconds;

    if (currentAuction!.id != null) {
      await _refreshRankings(currentAuction!.id!, 2);
    }
    _startTicker();
    _startCompetitorSimulation(2);

    notifyListeners();
  }

  Future<bool> placeBid(int transporterId, double amount, int stage, {int? tenderId}) async {
    final tId = tenderId ?? currentTender?.id ?? currentAuction?.tenderId;
    if (tId != null) {
      if (currentTender == null || currentTender!.id != tId) {
        currentTender = await _tenderService.getTenderById(tId);
      }
      if (currentAuction == null || currentAuction!.tenderId != tId) {
        currentAuction = await _auctionService.getAuctionByTenderId(tId);
      }
    }

    if (currentAuction == null && currentTender != null && currentTender!.id != null) {
      final now = DateTime.now();
      final isScheduled = currentTender!.biddingStart.isAfter(now);
      final auction = Auction(
        tenderId: currentTender!.id!,
        currentStage: 1,
        stage1Start: currentTender!.biddingStart,
        stage1End: currentTender!.softEnd,
        stage2Start: currentTender!.softEnd,
        stage2End: currentTender!.hardStop,
        status: isScheduled ? AuctionStatus.scheduled : AuctionStatus.stage1Live,
      );
      await _auctionService.saveAuction(auction);
      currentAuction = await _auctionService.getAuctionByTenderId(currentTender!.id!);
    }
    if (currentAuction == null || currentTender == null || currentAuction!.id == null) {
      return false;
    }

    final now = DateTime.now();
    if (stage == 1) {
      if (now.isBefore(currentAuction!.stage1Start) || now.isAfter(currentAuction!.stage1End)) {
        return false;
      }
      if (currentAuction!.status == AuctionStatus.scheduled &&
          (now.isAfter(currentAuction!.stage1Start) || now.isAtSameMomentAs(currentAuction!.stage1Start))) {
        currentAuction = currentAuction!.copyWith(status: AuctionStatus.stage1Live, currentStage: 1);
        await _auctionService.saveAuction(currentAuction!);
      }
      if (currentAuction!.status != AuctionStatus.stage1Live) {
        return false;
      }
    } else if (stage == 2) {
      if (now.isBefore(currentAuction!.stage2Start) || now.isAfter(currentAuction!.stage2End)) {
        return false;
      }
      if (currentAuction!.status != AuctionStatus.stage2Live) {
        return false;
      }
    }

    if (currentTender != null &&
        currentTender!.id != null &&
        currentTender!.status != TenderStatus.stage1 &&
        currentTender!.status != TenderStatus.stage2) {
      await _tenderService.setStatus(currentTender!.id!, stage == 2 ? TenderStatus.stage2 : TenderStatus.stage1);
      currentTender = await _tenderService.getTenderById(currentTender!.id!);
    }

    if (amount <= 0) return false;

    if (amount > currentTender!.ceilingBid) {
      return false;
    }

    final existingLatest = await _auctionService.getLatestBidFor(
      auctionId: currentAuction!.id!,
      transporterId: transporterId,
      stage: stage,
    );
    if (existingLatest != null && amount >= existingLatest.amount) {
      return false;
    }

    final myPrev = rankings.where((r) => r.transporterId == transporterId).firstOrNull;
    if (myPrev != null && amount >= myPrev.amount) {
      return false;
    }

    await _auctionService.invalidatePreviousBids(
      auctionId: currentAuction!.id!,
      transporterId: transporterId,
      stage: stage,
    );

    await _auctionService.insertBid(
      auctionId: currentAuction!.id!,
      tenderId: currentTender!.id!,
      transporterId: transporterId,
      amount: amount,
      stage: stage,
    );

    if (stage == 1) {
      final stageBids = await _auctionService.getValidStageBids(currentAuction!.id!, stage);
      final existingTransporterIds = stageBids.map((b) => b.transporterId).toSet();
      if (stageBids.length < 5) {
        final step = currentTender!.priceDifference > 0 ? currentTender!.priceDifference : 500.0;
        final competitors = [2, 3, 4, 5, 6].where((id) => !existingTransporterIds.contains(id)).toList();
        for (var i = 0; i < competitors.length && (stageBids.length + i) < 5; i++) {
          final cid = competitors[i];
          final competitorAmt = (amount + (step * (i + 1))).clamp(100.0, currentTender!.ceilingBid);
          if (competitorAmt > amount) {
            await _auctionService.insertBid(
              auctionId: currentAuction!.id!,
              tenderId: currentTender!.id!,
              transporterId: cid,
              amount: competitorAmt,
              stage: stage,
            );
          }
        }
      }
    }

    _checkExtension();
    await _refreshRankings(currentAuction!.id!, stage);

    return true;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
  }

  Future<void> _tick() async {
    if (secondsRemaining > 0) {
      secondsRemaining--;
      notifyListeners();
    } else {
      _ticker?.cancel();
      _competitorTimer?.cancel();

      if (currentAuction?.currentStage == 1) {
        currentAuction =
            currentAuction!.copyWith(status: AuctionStatus.stage1Completed);
        await _auctionService.saveAuction(currentAuction!);

        if (currentAuction!.id != null) {
          final topIds =
              rankings.take(5).map((r) => r.transporterId).toList();
          await _auctionService.markStage1Results(
            currentAuction!.id!,
            qualifiedTransporterIds: topIds,
          );
        }
        notifyListeners();
      } else if (currentAuction?.currentStage == 2) {
        await finalize();
      }
    }
  }

  void _startCompetitorSimulation(int stage) {
    _competitorTimer?.cancel();
    final minMs = stage == 2
        ? DemoConstants.stage2CompetitorMinDelay.inMilliseconds
        : DemoConstants.competitorBidMinInterval.inMilliseconds;
    final maxMs = stage == 2
        ? DemoConstants.stage2CompetitorMaxDelay.inMilliseconds
        : DemoConstants.competitorBidMaxInterval.inMilliseconds;

    void scheduleNext() {
      if (secondsRemaining <= 0) return;
      final delayMs = minMs + Random().nextInt(maxMs - minMs + 1);
      _competitorTimer =
          Timer(Duration(milliseconds: delayMs), () async {
        await _simulateCompetitorBid(stage);
        scheduleNext();
      });
    }

    scheduleNext();
  }

  Future<void> _simulateCompetitorBid(int stage) async {
    if (currentAuction == null ||
        currentTender == null ||
        secondsRemaining <= 0 ||
        currentAuction!.id == null) {
      return;
    }

    final competitorId = Random().nextInt(6) + 2;

    final currentLowest =
        rankings.isNotEmpty ? rankings.first.amount : (currentTender?.ceilingBid ?? DemoConstants.baseBidAmount);
    final multiples = Random().nextInt(3) + 1;
    final newAmount =
        currentLowest - (currentTender!.priceDifference * multiples);

    if (newAmount <= 0) return;

    await _auctionService.invalidatePreviousBids(
      auctionId: currentAuction!.id!,
      transporterId: competitorId,
      stage: stage,
    );
    await _auctionService.insertBid(
      auctionId: currentAuction!.id!,
      tenderId: currentTender!.id!,
      transporterId: competitorId,
      amount: newAmount,
      stage: stage,
    );

    _checkExtension();
    await _refreshRankings(currentAuction!.id!, stage);
  }

  void _checkExtension() {
    if (secondsRemaining <= DemoConstants.extensionWindow.inSeconds &&
        secondsRemaining > 0) {
      secondsRemaining += DemoConstants.extensionAmount.inSeconds;
    }
  }

  Future<void> _refreshRankings(int auctionId, int stage) async {
    final validBids = await _auctionService.getValidStageBids(auctionId, stage);
    validBids.sort((a, b) => a.amount.compareTo(b.amount));

    final transporterIds =
        validBids.map((b) => b.transporterId).toSet().toList();
    final nameMap = await _auctionService.getCompanyNames(transporterIds);

    final seen = <int>{};
    final unique = <Bid>[];
    for (final b in validBids) {
      if (seen.add(b.transporterId)) {
        unique.add(b);
      }
    }

    rankings = unique.asMap().entries.map((entry) {
      final index = entry.key;
      final bid = entry.value;
      final displayName = stage == 2
          ? 'Bidder ${index + 1}'
          : (nameMap[bid.transporterId] ?? 'Transporter ${bid.transporterId}');

      return RankingEntry(
        rank: index + 1,
        transporterId: bid.transporterId,
        transporterName: displayName,
        amount: bid.amount,
      );
    }).toList();

    notifyListeners();
  }

  Future<void> finalize() async {
    if (currentAuction == null || isFinalized || currentAuction!.id == null) {
      return;
    }

    _ticker?.cancel();
    _competitorTimer?.cancel();

    await _refreshRankings(currentAuction!.id!, currentAuction!.currentStage);

    if (rankings.isNotEmpty) {
      winnerTransporterId = rankings.first.transporterId;
      winningBid = rankings.first.amount;
      winnerName = rankings.first.transporterName;

      final result = AuctionResult(
        auctionId: currentAuction!.id!,
        winnerTransporterId: winnerTransporterId!,
        winnerName: winnerName!,
        winningBid: winningBid!,
        completedAt: DateTime.now(),
      );

      await _auctionService.saveResult(result);
      currentAuction = currentAuction!.copyWith(
        status: AuctionStatus.completed,
        winnerTransporterId: () => winnerTransporterId,
        finalPrice: () => winningBid,
      );
      await _auctionService.saveAuction(currentAuction!);
      if (currentTender?.id != null) {
        await _tenderService.setStatus(currentTender!.id!, TenderStatus.completed);
      }
    } else {
      currentAuction =
          currentAuction!.copyWith(status: AuctionStatus.completed);
      await _auctionService.saveAuction(currentAuction!);
      if (currentTender?.id != null) {
        await _tenderService.setStatus(currentTender!.id!, TenderStatus.completed);
      }
    }

    isFinalized = true;
    notifyListeners();
  }

  int myRank(int transporterId) {
    for (final r in rankings) {
      if (r.transporterId == transporterId) return r.rank;
    }
    return -1;
  }

  double? myBidAmount(int transporterId) {
    for (final r in rankings) {
      if (r.transporterId == transporterId) return r.amount;
    }
    return null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _ticker?.cancel();
    _ticker = null;
    _competitorTimer?.cancel();
    _competitorTimer = null;
    super.dispose();
  }
}
