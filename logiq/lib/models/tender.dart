import 'material_item.dart';

class Tender {
  final int id;
  final int creatorId;
  final String title;
  final String pickupLocation;
  final String dropLocation;
  final DateTime deliveryStart;
  final DateTime deliveryEnd;
  final DateTime tenderClosingDate;
  final DateTime biddingStartTime;
  final DateTime softEndTime;
  final DateTime hardStopTime;
  final double priceDifference;
  final String status;
  final List<MaterialItem> materials;
  final int participantCount;
  final DateTime createdAt;

  const Tender({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.pickupLocation,
    required this.dropLocation,
    required this.deliveryStart,
    required this.deliveryEnd,
    required this.tenderClosingDate,
    required this.biddingStartTime,
    required this.softEndTime,
    required this.hardStopTime,
    this.priceDifference = 25.0,
    required this.status,
    this.materials = const [],
    this.participantCount = 0,
    required this.createdAt,
  });

  factory Tender.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    return Tender(
      id: (json['id'] as num?)?.toInt() ?? 0,
      creatorId: (json['creator_id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      pickupLocation: json['pickup_location']?.toString() ?? '',
      dropLocation: json['drop_location']?.toString() ?? '',
      deliveryStart: parseDate(json['delivery_start']),
      deliveryEnd: parseDate(json['delivery_end']),
      tenderClosingDate: parseDate(json['tender_closing_date']),
      biddingStartTime: parseDate(json['bidding_start_time']),
      softEndTime: parseDate(json['soft_end_time']),
      hardStopTime: parseDate(json['hard_stop_time']),
      priceDifference: (json['price_difference'] as num?)?.toDouble() ?? 25.0,
      status: json['status']?.toString() ?? 'DRAFT',
      materials: (json['materials'] as List?)
              ?.map((e) => MaterialItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      participantCount: (json['participant_count'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'pickup_location': pickupLocation,
      'drop_location': dropLocation,
      'delivery_start': deliveryStart.toIso8601String().split('T')[0],
      'delivery_end': deliveryEnd.toIso8601String().split('T')[0],
      'tender_closing_date': tenderClosingDate.toIso8601String(),
      'bidding_start_time': biddingStartTime.toIso8601String(),
      'soft_end_time': softEndTime.toIso8601String(),
      'hard_stop_time': hardStopTime.toIso8601String(),
      'price_difference': priceDifference,
      'materials': materials.map((m) => m.toJson()).toList(),
    };
  }

  Tender copyWith({
    int? id,
    int? creatorId,
    String? title,
    String? pickupLocation,
    String? dropLocation,
    DateTime? deliveryStart,
    DateTime? deliveryEnd,
    DateTime? tenderClosingDate,
    DateTime? biddingStartTime,
    DateTime? softEndTime,
    DateTime? hardStopTime,
    double? priceDifference,
    String? status,
    List<MaterialItem>? materials,
    int? participantCount,
    DateTime? createdAt,
  }) {
    return Tender(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      title: title ?? this.title,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropLocation: dropLocation ?? this.dropLocation,
      deliveryStart: deliveryStart ?? this.deliveryStart,
      deliveryEnd: deliveryEnd ?? this.deliveryEnd,
      tenderClosingDate: tenderClosingDate ?? this.tenderClosingDate,
      biddingStartTime: biddingStartTime ?? this.biddingStartTime,
      softEndTime: softEndTime ?? this.softEndTime,
      hardStopTime: hardStopTime ?? this.hardStopTime,
      priceDifference: priceDifference ?? this.priceDifference,
      status: status ?? this.status,
      materials: materials ?? this.materials,
      participantCount: participantCount ?? this.participantCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
