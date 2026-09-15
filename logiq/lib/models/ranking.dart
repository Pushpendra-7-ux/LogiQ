class RankingEntry {
  final String rank;
  final int transporterId;
  final String transporterName;
  final double amount;

  const RankingEntry({
    required this.rank,
    required this.transporterId,
    required this.transporterName,
    required this.amount,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      rank: json['rank']?.toString() ?? '',
      transporterId: json['transporter_id'] is int
          ? json['transporter_id'] as int
          : int.tryParse(json['transporter_id']?.toString() ?? '') ?? 0,
      transporterName: json['transporter_name']?.toString() ?? '',
      amount: json['amount'] is num
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'transporter_id': transporterId,
      'transporter_name': transporterName,
      'amount': amount,
    };
  }

  RankingEntry copyWith({
    String? rank,
    int? transporterId,
    String? transporterName,
    double? amount,
  }) {
    return RankingEntry(
      rank: rank ?? this.rank,
      transporterId: transporterId ?? this.transporterId,
      transporterName: transporterName ?? this.transporterName,
      amount: amount ?? this.amount,
    );
  }
}typedef Ranking = RankingEntry;
