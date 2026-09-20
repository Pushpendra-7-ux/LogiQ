enum TenderStatus {
  draft('draft'),
  pendingPublish('pending_publish'),
  scheduled('scheduled'),
  stage1('stage1'),
  stage2('stage2'),
  completed('completed'),
  cancelled('cancelled');

  const TenderStatus(this.value);
  final String value;

  static TenderStatus fromValue(String? v) => TenderStatus.values.firstWhere(
        (s) => s.value == v,
        orElse: () => TenderStatus.draft,
      );

  String get label => switch (this) {
        draft => 'Draft',
        pendingPublish => 'Pending Publish',
        scheduled => 'Scheduled',
        stage1 => 'Round 1 Live',
        stage2 => 'Round 2 Live',
        completed => 'Completed',
        cancelled => 'Cancelled',
      };

  bool get isActive =>
      this == scheduled || this == stage1 || this == stage2;

  bool get isDraft => this == draft || this == pendingPublish;
}

class Tender {
  final int? id;
  final String title;
  final int createdBy;
  final String pickup;
  final String drop;
  final DateTime deliveryStart;
  final DateTime deliveryEnd;
  final DateTime closingDate;
  final DateTime biddingStart;
  final DateTime softEnd;
  final DateTime hardStop;
  final double priceDifference;
  final double ceilingBid;
  final double minDecrement;
  final String remarks;
  final String vehicleType;
  final DateTime? publishAt;
  final TenderStatus status;
  final DateTime createdAt;

  const Tender({
    this.id,
    required this.title,
    required this.createdBy,
    required this.pickup,
    required this.drop,
    required this.deliveryStart,
    required this.deliveryEnd,
    required this.closingDate,
    required this.biddingStart,
    required this.softEnd,
    required this.hardStop,
    this.priceDifference = 25.0,
    this.ceilingBid = 75000.0,
    this.minDecrement = 500.0,
    this.remarks = '',
    this.vehicleType = 'Truck',
    this.publishAt,
    this.status = TenderStatus.draft,
    required this.createdAt,
  });

  String get route => '$pickup → $drop';

  /// Short route for cards (city names only)
  String get shortRoute {
    final p = pickup.split(',').first.trim();
    final d = drop.split(',').first.trim();
    return '$p → $d';
  }

  bool get isPendingPublish => status == TenderStatus.pendingPublish;

  Duration get remainingDraftTime {
    if (publishAt == null) return Duration.zero;
    final remaining = publishAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get shouldAutoPublish =>
      isPendingPublish && publishAt != null && DateTime.now().isAfter(publishAt!);

  Tender copyWith({
    TenderStatus? status,
    String? title,
    String? pickup,
    String? drop,
    DateTime? deliveryStart,
    DateTime? deliveryEnd,
    DateTime? closingDate,
    DateTime? biddingStart,
    DateTime? softEnd,
    DateTime? hardStop,
    double? priceDifference,
    double? ceilingBid,
    double? minDecrement,
    String? remarks,
    String? vehicleType,
    DateTime? Function()? publishAt,
  }) =>
      Tender(
        id: id,
        title: title ?? this.title,
        createdBy: createdBy,
        pickup: pickup ?? this.pickup,
        drop: drop ?? this.drop,
        deliveryStart: deliveryStart ?? this.deliveryStart,
        deliveryEnd: deliveryEnd ?? this.deliveryEnd,
        closingDate: closingDate ?? this.closingDate,
        biddingStart: biddingStart ?? this.biddingStart,
        softEnd: softEnd ?? this.softEnd,
        hardStop: hardStop ?? this.hardStop,
        priceDifference: priceDifference ?? this.priceDifference,
        ceilingBid: ceilingBid ?? this.ceilingBid,
        minDecrement: minDecrement ?? this.minDecrement,
        remarks: remarks ?? this.remarks,
        vehicleType: vehicleType ?? this.vehicleType,
        publishAt: publishAt != null ? publishAt() : this.publishAt,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'created_by': createdBy,
        'delivery_from': pickup,
        'delivery_to': drop,
        'delivery_start': deliveryStart.toIso8601String(),
        'delivery_end': deliveryEnd.toIso8601String(),
        'closing_date': closingDate.toIso8601String(),
        'bidding_start': biddingStart.toIso8601String(),
        'soft_end': softEnd.toIso8601String(),
        'hard_stop': hardStop.toIso8601String(),
        'price_difference': priceDifference,
        'ceiling_bid': ceilingBid,
        'min_decrement': minDecrement,
        'remarks': remarks,
        'vehicle_type': vehicleType,
        'publish_at': publishAt?.toIso8601String(),
        'status': status.value,
        'created_at': createdAt.toIso8601String(),
      };

  factory Tender.fromMap(Map<String, Object?> m) => Tender(
        id: m['id'] as int?,
        title: (m['title'] ?? '') as String,
        createdBy: (m['created_by'] ?? 0) as int,
        pickup: (m['delivery_from'] ?? '') as String,
        drop: (m['delivery_to'] ?? '') as String,
        deliveryStart:
            DateTime.tryParse((m['delivery_start'] ?? '') as String) ?? DateTime.now(),
        deliveryEnd:
            DateTime.tryParse((m['delivery_end'] ?? '') as String) ?? DateTime.now(),
        closingDate:
            DateTime.tryParse((m['closing_date'] ?? '') as String) ?? DateTime.now(),
        biddingStart:
            DateTime.tryParse((m['bidding_start'] ?? '') as String) ?? DateTime.now(),
        softEnd: DateTime.tryParse((m['soft_end'] ?? '') as String) ?? DateTime.now(),
        hardStop:
            DateTime.tryParse((m['hard_stop'] ?? '') as String) ?? DateTime.now(),
        priceDifference: (m['price_difference'] as num? ?? 25.0).toDouble(),
        ceilingBid: (m['ceiling_bid'] as num? ?? 75000.0).toDouble(),
        minDecrement: (m['min_decrement'] as num? ?? 500.0).toDouble(),
        remarks: (m['remarks'] ?? '') as String,
        vehicleType: (m['vehicle_type'] ?? 'Truck') as String,
        publishAt: m['publish_at'] != null
            ? DateTime.tryParse((m['publish_at'] ?? '') as String)
            : null,
        status: TenderStatus.fromValue(m['status'] as String?),
        createdAt:
            DateTime.tryParse((m['created_at'] ?? '') as String) ?? DateTime.now(),
      );
}
