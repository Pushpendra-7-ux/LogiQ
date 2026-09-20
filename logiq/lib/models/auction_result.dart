class AuctionResult {
  final int? id;
  final int auctionId;
  final int winnerTransporterId;
  final String winnerName;
  final double winningBid;
  final DateTime completedAt;

  const AuctionResult({
    this.id,
    required this.auctionId,
    required this.winnerTransporterId,
    this.winnerName = '',
    required this.winningBid,
    required this.completedAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'auction_id': auctionId,
        'winner_transporter_id': winnerTransporterId,
        'winner_name': winnerName,
        'winning_bid': winningBid,
        'completed_at': completedAt.toIso8601String(),
      };

  factory AuctionResult.fromMap(Map<String, Object?> m) => AuctionResult(
        id: m['id'] as int?,
        auctionId: (m['auction_id'] ?? 0) as int,
        winnerTransporterId: (m['winner_transporter_id'] ?? 0) as int,
        winnerName: (m['winner_name'] ?? '') as String,
        winningBid: (m['winning_bid'] as num? ?? 0).toDouble(),
        completedAt:
            DateTime.tryParse((m['completed_at'] ?? '') as String) ?? DateTime.now(),
      );
}
