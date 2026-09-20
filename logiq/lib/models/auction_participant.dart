class AuctionParticipant {
  final int? id;
  final int auctionId;
  final int transporterId;
  final bool qualifiedStage2;
  final int? stage1Rank;

  const AuctionParticipant({
    this.id,
    required this.auctionId,
    required this.transporterId,
    this.qualifiedStage2 = false,
    this.stage1Rank,
  });

  AuctionParticipant copyWith({bool? qualifiedStage2, int? stage1Rank}) =>
      AuctionParticipant(
        id: id,
        auctionId: auctionId,
        transporterId: transporterId,
        qualifiedStage2: qualifiedStage2 ?? this.qualifiedStage2,
        stage1Rank: stage1Rank ?? this.stage1Rank,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'auction_id': auctionId,
        'transporter_id': transporterId,
        'qualified_stage2': qualifiedStage2 ? 1 : 0,
        'stage1_rank': stage1Rank,
      };

  factory AuctionParticipant.fromMap(Map<String, Object?> m) => AuctionParticipant(
        id: m['id'] as int?,
        auctionId: (m['auction_id'] ?? 0) as int,
        transporterId: (m['transporter_id'] ?? 0) as int,
        qualifiedStage2: (m['qualified_stage2'] as int? ?? 0) == 1,
        stage1Rank: (m['stage1_rank'] as num?)?.toInt(),
      );
}
