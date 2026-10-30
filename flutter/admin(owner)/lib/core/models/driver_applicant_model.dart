import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';

enum ApplicantStatus {
  pending,
  approved,
  rejected,
}

class DriverApplicantModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final bool isVerified;
  final String licenseNumber;
  final String vehicleType;
  final String plateNumber;
  final String vehicleModel;
  final double maxWeightKg;
  final String licenseDocUrl;
  final String registrationDocUrl;
  final String insuranceDocUrl;
  final DateTime appliedAt;
  final String? rejectionReason;

  const DriverApplicantModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.isVerified,
    required this.licenseNumber,
    required this.vehicleType,
    required this.plateNumber,
    required this.vehicleModel,
    this.maxWeightKg = 1500.0,
    required this.licenseDocUrl,
    required this.registrationDocUrl,
    required this.insuranceDocUrl,
    required this.appliedAt,
    this.rejectionReason,
  });

  ApplicantStatus get status {
    if (rejectionReason != null) return ApplicantStatus.rejected;
    return isVerified ? ApplicantStatus.approved : ApplicantStatus.pending;
  }

  Color get statusColor {
    switch (status) {
      case ApplicantStatus.approved:
        return AdminTheme.statusOnline; // Green
      case ApplicantStatus.pending:
        return const Color(0xFFF59E0B); // Amber
      case ApplicantStatus.rejected:
        return AdminTheme.crimsonRed;   // Red
    }
  }

  String get statusLabel {
    switch (status) {
      case ApplicantStatus.approved:
        return 'VERIFIED / ACTIVE';
      case ApplicantStatus.pending:
        return 'PENDING REVIEW';
      case ApplicantStatus.rejected:
        return 'REJECTED';
    }
  }

  DriverApplicantModel copyWith({
    bool? isVerified,
    String? rejectionReason,
  }) {
    return DriverApplicantModel(
      id: id,
      name: name,
      phone: phone,
      email: email,
      isVerified: isVerified ?? this.isVerified,
      licenseNumber: licenseNumber,
      vehicleType: vehicleType,
      plateNumber: plateNumber,
      vehicleModel: vehicleModel,
      maxWeightKg: maxWeightKg,
      licenseDocUrl: licenseDocUrl,
      registrationDocUrl: registrationDocUrl,
      insuranceDocUrl: insuranceDocUrl,
      appliedAt: appliedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  factory DriverApplicantModel.fromJson(Map<String, dynamic> json) {
    return DriverApplicantModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Applicant').toString(),
      phone: (json['phone'] ?? '+91 98000 00000').toString(),
      email: (json['email'] ?? '').toString(),
      isVerified: json['is_verified'] == true,
      licenseNumber: (json['license_number'] ?? 'DL-MH04-2024-9988').toString(),
      vehicleType: (json['vehicle_type'] ?? 'van').toString(),
      plateNumber: (json['plate_number'] ?? 'MH-04-AP-0000').toString(),
      vehicleModel: (json['vehicle_model'] ?? 'Tata Ace Gold').toString(),
      maxWeightKg: ((json['max_weight_kg'] ?? 1000) as num).toDouble(),
      licenseDocUrl: (json['license_doc_url'] ?? 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600').toString(),
      registrationDocUrl: (json['registration_doc_url'] ?? 'https://images.unsplash.com/photo-1580273916550-e323be2ae537?w=600').toString(),
      insuranceDocUrl: (json['insurance_doc_url'] ?? 'https://images.unsplash.com/photo-1450133064473-71024230f91b?w=600').toString(),
      appliedAt: DateTime.tryParse(json['applied_at']?.toString() ?? '') ?? DateTime.now(),
      rejectionReason: json['rejection_reason']?.toString(),
    );
  }
}

