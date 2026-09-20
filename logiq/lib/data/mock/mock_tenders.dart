import '../../core/constants/demo_constants.dart';
import '../../models/tender.dart';

/// Relative-time tender templates used by the seeder.
class MockTenders {
  MockTenders._();

  static const String liveDemoTitle = 'Steel Transport';
  static const String history1Title = 'Coal Transport';
  static const String history2Title = 'Cement Transport';

  /// Freshly re-timed so the auction can be started any time the app runs.
  static Tender liveDemo({required int createdBy}) {
    final now = DateTime.now();
    return Tender(
      title: liveDemoTitle,
      createdBy: createdBy,
      pickup: 'Gwalior',
      drop: 'Raipur',
      deliveryStart: now.add(const Duration(days: 3)),
      deliveryEnd: now.add(const Duration(days: 5)),
      closingDate: now.add(const Duration(hours: 2)),
      biddingStart: now.add(DemoConstants.demoStartDelay),
      softEnd: now.add(DemoConstants.demoStartDelay + DemoConstants.stage1Duration),
      hardStop: now.add(DemoConstants.demoStartDelay +
          DemoConstants.stage1Duration +
          DemoConstants.hardStopBuffer),
      priceDifference: DemoConstants.defaultPriceDifference,
      status: TenderStatus.scheduled,
      createdAt: now,
    );
  }

  static Tender history1({required int createdBy}) {
    final created = DateTime.now().subtract(const Duration(days: 7));
    return Tender(
      title: history1Title,
      createdBy: createdBy,
      pickup: 'Nagpur',
      drop: 'Pune',
      deliveryStart: created.add(const Duration(days: 2)),
      deliveryEnd: created.add(const Duration(days: 4)),
      closingDate: created.subtract(const Duration(hours: 1)),
      biddingStart: created,
      softEnd: created.add(DemoConstants.stage1Duration),
      hardStop: created
          .add(DemoConstants.stage1Duration + DemoConstants.hardStopBuffer),
      priceDifference: DemoConstants.defaultPriceDifference,
      status: TenderStatus.completed,
      createdAt: created,
    );
  }

  static Tender history2({required int createdBy}) {
    final created = DateTime.now().subtract(const Duration(days: 12));
    return Tender(
      title: history2Title,
      createdBy: createdBy,
      pickup: 'Bhopal',
      drop: 'Indore',
      deliveryStart: created.add(const Duration(days: 2)),
      deliveryEnd: created.add(const Duration(days: 3)),
      closingDate: created.subtract(const Duration(hours: 1)),
      biddingStart: created,
      softEnd: created.add(DemoConstants.stage1Duration),
      hardStop: created
          .add(DemoConstants.stage1Duration + DemoConstants.hardStopBuffer),
      priceDifference: DemoConstants.defaultPriceDifference,
      status: TenderStatus.completed,
      createdAt: created,
    );
  }
}
