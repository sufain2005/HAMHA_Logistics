class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isVerified;
  final String companyName;
  final String gstin;
  final String primaryAddress;
  final String upiId;
  final bool whatsappAlerts;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.isVerified = false,
    this.companyName = '',
    this.gstin = '',
    this.primaryAddress = '',
    this.upiId = '',
    this.whatsappAlerts = true,
    this.avatarUrl,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    bool? isVerified,
    String? companyName,
    String? gstin,
    String? primaryAddress,
    String? upiId,
    bool? whatsappAlerts,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      companyName: companyName ?? this.companyName,
      gstin: gstin ?? this.gstin,
      primaryAddress: primaryAddress ?? this.primaryAddress,
      upiId: upiId ?? this.upiId,
      whatsappAlerts: whatsappAlerts ?? this.whatsappAlerts,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'customer',
      isVerified: json['is_verified'] ?? false,
      companyName: json['company_name'] ?? json['companyName'] ?? '',
      gstin: json['gstin'] ?? '',
      primaryAddress: json['primary_address'] ?? json['primaryAddress'] ?? '',
      upiId: json['upi_id'] ?? json['upiId'] ?? '',
      whatsappAlerts: json['whatsapp_alerts'] ?? json['whatsappAlerts'] ?? true,
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'is_verified': isVerified,
    'company_name': companyName,
    'gstin': gstin,
    'primary_address': primaryAddress,
    'upi_id': upiId,
    'whatsapp_alerts': whatsappAlerts,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
  };
}
