import 'dart:async';
import 'dart:math';

import 'package:logiq/core/constants/demo_constants.dart';
import 'package:logiq/data/local/local_bid_data_source.dart';
import 'package:logiq/models/bid.dart';

/// Simulates competitor transporters placing bids during the live auction demo.
///
/// Uses random intervals and amounts so each demo feels different.
/// When the company REST API arrives, this class is removed entirely —
/// real competitor bids come from WebSocket / polling.
class MockAuctionEngine {
  MockAuctionEngine({
    required this.auctionId,
    required this.tenderId,
    required this.competitorIds,
    required this.excludeTransporterId,
    required this.priceDifference,
    required this.onBidPlaced,
  });

  final int auctionId;
  final int tenderId;
  final List<int> competitorIds;
  final int excludeTransporterId; // the logged-in transporter — don't auto-bid for them
  final double priceDifference;
  final void Function(Bid bid) onBidPlaced;

  final _rng = Random();
  final _bidSource = LocalBidDataSource.instance;
  Timer? _timer;
  bool _disposed = false;

  double _currentLowest = DemoConstants.baseBidAmount;

  /// Start simulating Stage 1 competitor bids.
  void startStage1() {
    _currentLowest = DemoConstants.baseBidAmount;
    _scheduleNext(isStage2: false);
  }

  /// Start simulating Stage 2 competitor bids with tighter intervals.
  void startStage2({required double currentLowest}) {
    _currentLowest = currentLowest;
    _scheduleNext(isStage2: true);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _disposed = true;
    stop();
  }

  void updateLowest(double amount) {
    if (amount < _currentLowest) {
      _currentLowest = amount;
    }
  }

  void _scheduleNext({required bool isStage2}) {
    if (_disposed) return;

    final minMs = isStage2
        ? DemoConstants.stage2CompetitorMinDelay.inMilliseconds
        : DemoConstants.competitorBidMinInterval.inMilliseconds;
    final maxMs = isStage2
        ? DemoConstants.stage2CompetitorMaxDelay.inMilliseconds
        : DemoConstants.competitorBidMaxInterval.inMilliseconds;

    final delayMs = minMs + _rng.nextInt(maxMs - minMs + 1);
    _timer = Timer(Duration(milliseconds: delayMs), () {
      if (_disposed) return;
      _placeMockBid(isStage2: isStage2);
    });
  }

  Future<void> _placeMockBid({required bool isStage2}) async {
    if (_disposed) return;

    // Pick a random competitor (not the logged-in transporter)
    final competitors =
        competitorIds.where((id) => id != excludeTransporterId).toList();
    if (competitors.isEmpty) return;

    final transporterId = competitors[_rng.nextInt(competitors.length)];

    // Decide bid amount: underbid current lowest by 1-4x priceDifference
    final multiplier = 1 + _rng.nextInt(4); // 1, 2, 3, or 4
    final bidAmount = _currentLowest - (priceDifference * multiplier);

    if (bidAmount <= 0) {
      // Prices bottomed out — stop competing
      _scheduleNext(isStage2: isStage2);
      return;
    }

    try {
      // Invalidate previous bids for this competitor
      await _bidSource.invalidatePrevious(
        auctionId: auctionId,
        transporterId: transporterId,
        stage: isStage2 ? 2 : 1,
      );

      final bid = await _bidSource.insert(
        auctionId: auctionId,
        tenderId: tenderId,
        transporterId: transporterId,
        amount: bidAmount,
        stage: isStage2 ? 2 : 1,
      );

      _currentLowest = bidAmount;

      if (!_disposed) {
        onBidPlaced(bid);
      }
    } catch (_) {
      // Silently ignore DB errors in mock engine
    }

    // Schedule next competitor bid
    _scheduleNext(isStage2: isStage2);
  }
}
