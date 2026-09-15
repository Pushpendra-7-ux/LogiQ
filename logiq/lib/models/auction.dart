// auction.dart
import 'dart:math';

class Auction {
  final int? tenderId;
  final int stage;
  final String status;
  final DateTime startTime;
  final DateTime softEndTime;
  final DateTime hardStopTime;
  final double remainingSeconds;
  final DateTime serverTime;

  const Auction({
    this.tenderId,
    required this.stage,
    required this.status,
    required this.startTime,
    required this.softEndTime,
    required this.hardStopTime,
    required this.remainingSeconds,
    required this.serverTime,
  });

  factory Auction.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    return Auction(
      tenderId: (json['tender_id'] as num?)?.toInt(),
      stage: (json['stage'] as num?)?.toInt() ?? 1,
      status: json['status']?.toString() ?? 'SCHEDULED',
      startTime: parseDate(json['start_time'] ?? json['started_at']),
      softEndTime: parseDate(json['soft_end_time']),
      hardStopTime: parseDate(json['hard_stop_time']),
      remainingSeconds: (json['remaining_seconds'] as num?)?.toDouble() ?? 0.0,
      serverTime: parseDate(json['server_time']),
    );
  }

  Map<String, dynamic> toJson() => {
        'tender_id': tenderId,
        'stage': stage,
        'status': status,
        'start_time': startTime.toIso8601String(),
        'soft_end_time': softEndTime.toIso8601String(),
        'hard_stop_time': hardStopTime.toIso8601String(),
        'remaining_seconds': remainingSeconds,
        'server_time': serverTime.toIso8601String(),
      };

  bool get isLive => status == 'LIVE' || status == 'EXTENDED';

  bool get isSoftClosed => serverTime.isAfter(softEndTime);

  bool get isHardStopped => serverTime.isAfter(hardStopTime);

  double get effectiveRemainingSeconds => max(0, remainingSeconds);

  Auction copyWith({
    int? tenderId,
    int? stage,
    String? status,
    DateTime? startTime,
    DateTime? softEndTime,
    DateTime? hardStopTime,
    double? remainingSeconds,
    DateTime? serverTime,
  }) =>
      Auction(
        tenderId: tenderId ?? this.tenderId,
        stage: stage ?? this.stage,
        status: status ?? this.status,
        startTime: startTime ?? this.startTime,
        softEndTime: softEndTime ?? this.softEndTime,
        hardStopTime: hardStopTime ?? this.hardStopTime,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        serverTime: serverTime ?? this.serverTime,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Auction &&
          runtimeType == other.runtimeType &&
          tenderId == other.tenderId &&
          stage == other.stage &&
          status == other.status &&
          startTime == other.startTime &&
          softEndTime == other.softEndTime &&
          hardStopTime == other.hardStopTime &&
          remainingSeconds == other.remainingSeconds &&
          serverTime == other.serverTime;

  @override
  int get hashCode =>
      tenderId.hashCode ^
      stage.hashCode ^
      status.hashCode ^
      startTime.hashCode ^
      softEndTime.hashCode ^
      hardStopTime.hashCode ^
      remainingSeconds.hashCode ^
      serverTime.hashCode;

  @override
  String toString() =>
      'Auction(tenderId: $tenderId, stage: $stage, status: $status, remainingSeconds: $remainingSeconds)';
}