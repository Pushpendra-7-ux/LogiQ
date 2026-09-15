class TransporterProfile {
  final String companyName;
  final String companyEmail;
  final String whatsappPhone;
  final String gstNumber;
  final String transportId;

  const TransporterProfile({
    required this.companyName,
    required this.companyEmail,
    required this.whatsappPhone,
    required this.gstNumber,
    required this.transportId,
  });

  factory TransporterProfile.fromJson(Map<String, dynamic> json) {
    return TransporterProfile(
      companyName: json['company_name'] as String? ?? '',
      companyEmail: json['company_email'] as String? ?? '',
      whatsappPhone: json['whatsapp_phone'] as String? ?? '',
      gstNumber: json['gst_number'] as String? ?? '',
      transportId: json['transport_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_name': companyName,
      'company_email': companyEmail,
      'whatsapp_phone': whatsappPhone,
      'gst_number': gstNumber,
      'transport_id': transportId,
    };
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final DateTime createdAt;
  final TransporterProfile? transporterProfile;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    required this.createdAt,
    this.transporterProfile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final profile = json['transporter_profile'];

    return User(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'user',
      status: json['status'] as String? ?? 'pending',
      createdAt: _parseDateTime(json['created_at']),
      transporterProfile: profile is Map
          ? TransporterProfile.fromJson(Map<String, dynamic>.from(profile))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'transporter_profile': transporterProfile?.toJson(),
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';
  bool get isTransporter => role == 'transporter';
  bool get isApproved => status == 'approved';
}

DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}