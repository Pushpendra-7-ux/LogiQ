enum AuctionStatus {
  scheduled('scheduled'),
  stage1Live('stage1_live'),
  stage1Completed('stage1_completed'),
  stage2Live('stage2_live'),
  completed('completed'),
  cancelled('cancelled');

  const AuctionStatus(this.value);
  final String value;

  static AuctionStatus fromValue(String? v) => AuctionStatus.values.firstWhere(
        (s) => s.value == v,
        orElse: () => AuctionStatus.scheduled,
      );

  bool get isFinished => this == completed || this == cancelled;
  bool get isRunning =>
      this == scheduled || this == stage1Live || this == stage1Completed || this == stage2Live;
}

class Auction {
  final int? id;
  final int tenderId;
  final int currentStage;
  final DateTime stage1Start;
  final DateTime stage1End;
  final DateTime stage2Start;
  final DateTime stage2End;
  final AuctionStatus status;
  final int? winnerTransporterId;
  final double? finalPrice;

  const Auction({
    this.id,
    required this.tenderId,
    this.currentStage = 0,
    required this.stage1Start,
    required this.stage1End,
    required this.stage2Start,
    required this.stage2End,
    this.status = AuctionStatus.scheduled,
    this.winnerTransporterId,
    this.finalPrice,
  });

  bool get isStage1Live => status == AuctionStatus.stage1Live;
  bool get isStage2Live => status == AuctionStatus.stage2Live;

  Auction copyWith({
    int? currentStage,
    DateTime? stage1Start,
    DateTime? stage1End,
    DateTime? stage2Start,
    DateTime? stage2End,
    AuctionStatus? status,
    int? Function()? winnerTransporterId,
    double? Function()? finalPrice,
  }) =>
      Auction(
        id: id,
        tenderId: tenderId,
        currentStage: currentStage ?? this.currentStage,
        stage1Start: stage1Start ?? this.stage1Start,
        stage1End: stage1End ?? this.stage1End,
        stage2Start: stage2Start ?? this.stage2Start,
        stage2End: stage2End ?? this.stage2End,
        status: status ?? this.status,
        winnerTransporterId:
            winnerTransporterId != null ? winnerTransporterId() : this.winnerTransporterId,
        finalPrice: finalPrice != null ? finalPrice() : this.finalPrice,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'tender_id': tenderId,
        'current_stage': currentStage,
        'stage1_start': stage1Start.toIso8601String(),
        'stage1_end': stage1End.toIso8601String(),
        'stage2_start': stage2Start.toIso8601String(),
        'stage2_end': stage2End.toIso8601String(),
        'status': status.value,
        'winner_transporter_id': winnerTransporterId,
        'final_price': finalPrice,
      };

  factory Auction.fromMap(Map<String, Object?> m) => Auction(
        id: m['id'] as int?,
        tenderId: (m['tender_id'] ?? 0) as int,
        currentStage: (m['current_stage'] as num? ?? 0).toInt(),
        stage1Start:
            _dt(m['stage1_start']),
        stage1End: _dt(m['stage1_end']),
        stage2Start: _dt(m['stage2_start']),
        stage2End: _dt(m['stage2_end']),
        status: AuctionStatus.fromValue(m['status'] as String?),
        winnerTransporterId: m['winner_transporter_id'] as int?,
        finalPrice: (m['final_price'] as num?)?.toDouble(),
      );

  static DateTime _dt(Object? v) =>
      DateTime.tryParse((v ?? '') as String) ?? DateTime.now();
}

/// One line in the public Stage-1 leaderboard.
class RankingEntry {
  final int rank;
  final int transporterId;
  final String transporterName;
  final double amount;

  const RankingEntry({
    required this.rank,
    required this.transporterId,
    required this.transporterName,
    required this.amount,
  });

  String get label => 'L$rank';
}
