class Bid {
  final int? id;
  final int auctionId;
  final int tenderId;
  final int transporterId;
  final double amount;
  final int stage;
  final DateTime submittedAt;
  final bool isValid;

  const Bid({
    this.id,
    required this.auctionId,
    required this.tenderId,
    required this.transporterId,
    required this.amount,
    required this.stage,
    required this.submittedAt,
    this.isValid = true,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'auction_id': auctionId,
        'tender_id': tenderId,
        'transporter_id': transporterId,
        'amount': amount,
        'stage': stage,
        'submitted_at': submittedAt.toIso8601String(),
        'is_valid': isValid ? 1 : 0,
      };

  factory Bid.fromMap(Map<String, Object?> m) => Bid(
        id: m['id'] as int?,
        auctionId: (m['auction_id'] ?? 0) as int,
        tenderId: (m['tender_id'] ?? 0) as int,
        transporterId: (m['transporter_id'] ?? 0) as int,
        amount: (m['amount'] as num? ?? 0).toDouble(),
        stage: (m['stage'] ?? 1) as int,
        submittedAt:
            DateTime.tryParse((m['submitted_at'] ?? '') as String) ?? DateTime.now(),
        isValid: (m['is_valid'] as int? ?? 1) == 1,
      );
}
