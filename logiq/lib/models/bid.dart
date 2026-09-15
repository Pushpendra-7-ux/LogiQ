class Bid {
  final int id;
  final int auctionId;
  final int transporterId;
  final int stage;
  final double amount;
  final DateTime submittedAt;
  final String status;

  Bid({
    required this.id,
    required this.auctionId,
    required this.transporterId,
    required this.stage,
    required this.amount,
    required this.submittedAt,
    required this.status,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: (json['id'] as num?)?.toInt() ?? 0,
      auctionId: (json['auction_id'] as num?)?.toInt() ?? 0,
      transporterId: (json['transporter_id'] as num?)?.toInt() ?? 0,
      stage: (json['stage'] as num?)?.toInt() ?? 1,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      submittedAt: DateTime.tryParse(json['submitted_at']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? 'valid',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auction_id': auctionId,
      'transporter_id': transporterId,
      'stage': stage,
      'amount': amount,
      'submitted_at': submittedAt.toIso8601String(),
      'status': status,
    };
  }
}