import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';

class DisputeModel {
  final String id;
  final String orderCode;
  final String customerName;
  final String customerPhone;
  final String driverName;
  final String driverPhone;
  final String type; // 'delayed_transit', 'cargo_handling', 'toll_reimbursement'
  final String severity; // 'high', 'medium', 'low'
  final String status; // 'open', 'under_investigation', 'resolved'
  final int customerRating; // 1 to 5
  final String customerComplaint;
  final String driverExplanation;
  final DateTime filedAt;
  final double refundAmount;

  const DisputeModel({
    required this.id,
    required this.orderCode,
    required this.customerName,
    required this.customerPhone,
    required this.driverName,
    required this.driverPhone,
    required this.type,
    required this.severity,
    required this.status,
    required this.customerRating,
    required this.customerComplaint,
    required this.driverExplanation,
    required this.filedAt,
    required this.refundAmount,
  });

  Color get severityColor {
    switch (severity.toLowerCase()) {
      case 'high':
        return AdminTheme.crimsonRed;
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFF38BDF8);
      default:
        return AdminTheme.textMuted;
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'open':
        return AdminTheme.crimsonRed;
      case 'under_investigation':
        return const Color(0xFFF59E0B);
      case 'resolved':
        return AdminTheme.statusOnline;
      default:
        return AdminTheme.textMuted;
    }
  }

  String get typeLabel {
    switch (type.toLowerCase()) {
      case 'delayed_transit':
        return 'Transit SLA Delay';
      case 'cargo_handling':
        return 'Cargo Handling / Packaging';
      case 'toll_reimbursement':
        return 'FASTag Toll Dispute';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  DisputeModel copyWith({
    String? status,
  }) {
    return DisputeModel(
      id: id,
      orderCode: orderCode,
      customerName: customerName,
      customerPhone: customerPhone,
      driverName: driverName,
      driverPhone: driverPhone,
      type: type,
      severity: severity,
      status: status ?? this.status,
      customerRating: customerRating,
      customerComplaint: customerComplaint,
      driverExplanation: driverExplanation,
      filedAt: filedAt,
      refundAmount: refundAmount,
    );
  }

  factory DisputeModel.fromJson(Map<String, dynamic> json) {
    return DisputeModel(
      id: (json['id'] ?? 'DSP-000').toString(),
      orderCode: (json['order_code'] ?? 'HMH-00000').toString(),
      customerName: (json['customer_name'] ?? 'Client').toString(),
      customerPhone: (json['customer_phone'] ?? '').toString(),
      driverName: (json['driver_name'] ?? 'Driver').toString(),
      driverPhone: (json['driver_phone'] ?? '').toString(),
      type: (json['type'] ?? 'delayed_transit').toString(),
      severity: (json['severity'] ?? 'medium').toString(),
      status: (json['status'] ?? 'open').toString(),
      customerRating: ((json['customer_rating'] ?? 3) as num).toInt(),
      customerComplaint: (json['customer_complaint'] ?? 'No complaint details provided.').toString(),
      driverExplanation: (json['driver_explanation'] ?? 'Awaiting carrier statement.').toString(),
      filedAt: DateTime.tryParse(json['filed_at']?.toString() ?? '') ?? DateTime.now(),
      refundAmount: ((json['refund_amount'] ?? 0.0) as num).toDouble(),
    );
  }
}

