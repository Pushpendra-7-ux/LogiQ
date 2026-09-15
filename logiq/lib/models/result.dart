class AuctionResult {
  final int tenderId;
  final String winnerName;
  final String? winnerCompany;
  final double winningBid;
  final int stage;
  final DateTime finalizedAt;

  AuctionResult({
    required this.tenderId,
    required this.winnerName,
    this.winnerCompany,
    required this.winningBid,
    required this.stage,
    required this.finalizedAt,
  });

  factory AuctionResult.fromJson(Map<String, dynamic> json) => AuctionResult(
    tenderId: (json['tender_id'] as num?)?.toInt() ?? 0,
    winnerName: json['winner']?['name']?.toString() ?? json['winner_name']?.toString() ?? '',
    winnerCompany: json['winner']?['company_name']?.toString() ?? json['winner_company']?.toString(),
    winningBid: (json['winning_bid'] as num?)?.toDouble() ?? (json['winning_amount'] as num?)?.toDouble() ?? 0.0,
    stage: (json['stage'] as num?)?.toInt() ?? 2,
    finalizedAt: DateTime.tryParse(json['finalized_at']?.toString() ?? json['decided_at']?.toString() ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'tender_id': tenderId,
    'winner_name': winnerName,
    'winner_company': winnerCompany,
    'winning_bid': winningBid,
    'stage': stage,
    'finalized_at': finalizedAt.toIso8601String(),
  };
}
