import '../../core/constants/demo_constants.dart';
import '../../models/bid.dart';
import '../../models/transporter.dart';

/// Seed bids for the completed demo tenders (history screens).
/// Live demo bidding itself is simulated by MockAuctionEngine, not seeded.
class MockBids {
  MockBids._();

  /// History tender: Steel Transport — transporter 1 wins stage 2 with 9500.
  static List<Bid> historyStage1({required int auctionId, required int tenderId}) {
    final t = DateTime.now().subtract(const Duration(days: 7));
    const rows = [
      // transporterId, amount
      [1, 49500.0],
      [2, 49750.0],
      [3, 50000.0],
      [4, 50250.0],
      [5, 49800.0],
    ];
    return [
      for (var i = 0; i < rows.length; i++)
        Bid(
          auctionId: auctionId,
          tenderId: tenderId,
          transporterId: rows[i][0].toInt(),
          amount: rows[i][1].toDouble(),
          stage: 1,
          submittedAt: t.add(Duration(seconds: 10 * i)),
        ),
    ];
  }

  static List<Bid> historyStage2({required int auctionId, required int tenderId}) {
    final t = DateTime.now().subtract(const Duration(days: 7, hours: -1));
    const rows = [
      [1, 9500.0],
      [2, 9800.0],
      [3, 9700.0],
      [4, 9900.0],
      [5, 9650.0],
    ];
    return [
      for (var i = 0; i < rows.length; i++)
        Bid(
          auctionId: auctionId,
          tenderId: tenderId,
          transporterId: rows[i][0].toInt(),
          amount: rows[i][1].toDouble(),
          stage: 2,
          submittedAt: t.add(Duration(seconds: 20 * i)),
        ),
    ];
  }

  /// Second history tender: Cement Transport — transporter 1 lost.
  static List<Bid> history2Stage1({required int auctionId, required int tenderId}) {
    final t = DateTime.now().subtract(const Duration(days: 12));
    const rows = [
      [1, 15000.0],
      [3, 14500.0],
      [6, 14800.0],
      [7, 15200.0],
    ];
    return [
      for (var i = 0; i < rows.length; i++)
        Bid(
          auctionId: auctionId,
          tenderId: tenderId,
          transporterId: rows[i][0].toInt(),
          amount: rows[i][1].toDouble(),
          stage: 1,
          submittedAt: t.add(Duration(seconds: 15 * i)),
        ),
    ];
  }

  static List<Bid> history2Stage2({required int auctionId, required int tenderId}) {
    final t = DateTime.now().subtract(const Duration(days: 12, hours: -1));
    const rows = [
      [1, 14200.0],
      [3, 13900.0],
      [6, 14400.0],
      [7, 14900.0],
    ];
    return [
      for (var i = 0; i < rows.length; i++)
        Bid(
          auctionId: auctionId,
          tenderId: tenderId,
          transporterId: rows[i][0].toInt(),
          amount: rows[i][1].toDouble(),
          stage: 2,
          submittedAt: t.add(Duration(seconds: 18 * i)),
        ),
    ];
  }

  /// Convenience: human names for ranking rows of mock data.
  static String nameOf(List<Transporter> transporters, int transporterId) {
    for (final t in transporters) {
      if (t.id == transporterId) return t.companyName;
    }
    return 'Transporter $transporterId';
  }

  static double get demoBaseBid => DemoConstants.baseBidAmount;
}
