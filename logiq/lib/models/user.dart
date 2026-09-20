class AppUser {
  final int? id;
  final String name;
  final String companyName;
  final String email;
  final String password;
  final String role;
  final String phone;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String rejectionReason;
  final DateTime createdAt;

  const AppUser({
    this.id,
    required this.name,
    this.companyName = '',
    required this.email,
    required this.password,
    required this.role,
    this.phone = '',
    this.status = statusApproved,
    this.rejectionReason = '',
    required this.createdAt,
  });

  static const roleAdmin = 'admin';
  static const roleUser = 'user';
  static const roleShipper = 'shipper';
  static const roleTransporter = 'transporter';

  static const statusPending = 'pending';
  static const statusApproved = 'approved';
  static const statusRejected = 'rejected';

  bool get isAdmin => role == roleAdmin;
  bool get isUser => role == roleUser || role == roleShipper;
  bool get isShipper => role == roleShipper || role == roleUser;
  bool get isTransporter => role == roleTransporter;

  bool get isApproved => status == statusApproved;
  bool get isPending => status == statusPending;
  bool get isRejected => status == statusRejected;

  String get displayRole {
    if (isAdmin) return 'Admin';
    if (isTransporter) return 'Transporter';
    return 'User';
  }

  AppUser copyWith({
    int? id,
    String? name,
    String? companyName,
    String? email,
    String? password,
    String? role,
    String? phone,
    String? status,
    String? rejectionReason,
    bool? isApproved,
    DateTime? createdAt,
  }) =>
      AppUser(
        id: id ?? this.id,
        name: name ?? this.name,
        companyName: companyName ?? this.companyName,
        email: email ?? this.email,
        password: password ?? this.password,
        role: role ?? this.role,
        phone: phone ?? this.phone,
        status: status ??
            (isApproved != null
                ? (isApproved ? statusApproved : statusPending)
                : this.status),
        rejectionReason: rejectionReason ?? this.rejectionReason,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'company_name': companyName,
        'email': email,
        'password': password,
        'role': role,
        'phone': phone,
        'status': status,
        'rejection_reason': rejectionReason,
        'is_approved': isApproved ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory AppUser.fromMap(Map<String, Object?> m) {
    String status = (m['status'] as String?) ?? '';
    if (status.isEmpty) {
      final isApprovedInt = m['is_approved'] as int? ?? 1;
      status = isApprovedInt == 1 ? statusApproved : statusPending;
    }
    return AppUser(
      id: m['id'] as int?,
      name: (m['name'] ?? '') as String,
      companyName: (m['company_name'] ?? '') as String,
      email: (m['email'] ?? '') as String,
      password: (m['password'] ?? '') as String,
      role: (m['role'] ?? 'user') as String,
      phone: (m['phone'] ?? '') as String,
      status: status,
      rejectionReason: (m['rejection_reason'] ?? '') as String,
      createdAt:
          DateTime.tryParse((m['created_at'] ?? '') as String) ?? DateTime.now(),
    );
  }
}
