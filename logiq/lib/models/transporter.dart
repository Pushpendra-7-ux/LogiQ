class Transporter {
  final int? id;
  final int userId;
  final String companyName;
  final String gstin;
  final String vahanId;
  final bool isApproved;
  final double rating;
  final int tripCount;
  final String fleetSize;
  final String transportCode;

  const Transporter({
    this.id,
    required this.userId,
    required this.companyName,
    this.gstin = '',
    this.vahanId = '',
    this.isApproved = true,
    this.rating = 4.5,
    this.tripCount = 0,
    this.fleetSize = '50+',
    this.transportCode = '',
  });

  String get name => companyName;

  /// Two-letter monogram for avatar circle
  String get monogram {
    final parts = companyName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return companyName.substring(0, companyName.length >= 2 ? 2 : companyName.length).toUpperCase();
  }

  Transporter copyWith({bool? isApproved}) => Transporter(
        id: id,
        userId: userId,
        companyName: companyName,
        gstin: gstin,
        vahanId: vahanId,
        isApproved: isApproved ?? this.isApproved,
        rating: rating,
        tripCount: tripCount,
        fleetSize: fleetSize,
        transportCode: transportCode,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'user_id': userId,
        'company_name': companyName,
        'gstin': gstin,
        'vahan_transport_id': vahanId,
        'is_approved': isApproved ? 1 : 0,
      };

  factory Transporter.fromMap(Map<String, Object?> m) => Transporter(
        id: m['id'] as int?,
        userId: (m['user_id'] ?? 0) as int,
        companyName: (m['company_name'] ?? '') as String,
        gstin: (m['gstin'] ?? '') as String,
        vahanId: (m['vahan_transport_id'] ?? '') as String,
        isApproved: (m['is_approved'] as int? ?? 1) == 1,
      );

  /// Enriched factory used for display in transporter selection UI.
  /// Adds display-only fields that aren't persisted in SQLite.
  Transporter withDisplayData({
    double? rating,
    int? tripCount,
    String? fleetSize,
    String? transportCode,
  }) =>
      Transporter(
        id: id,
        userId: userId,
        companyName: companyName,
        gstin: gstin,
        vahanId: vahanId,
        isApproved: isApproved,
        rating: rating ?? this.rating,
        tripCount: tripCount ?? this.tripCount,
        fleetSize: fleetSize ?? this.fleetSize,
        transportCode: transportCode ?? this.transportCode,
      );
}
