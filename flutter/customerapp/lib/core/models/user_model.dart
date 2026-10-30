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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'customer',
      isVerified: json['is_verified'] ?? false,
      companyName: json['company_name'] ?? '',
      gstin: json['gstin'] ?? '',
      primaryAddress: json['primary_address'] ?? '',
      upiId: json['upi_id'] ?? '',
      whatsappAlerts: json['whatsapp_alerts'] ?? true,
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
  };
}
