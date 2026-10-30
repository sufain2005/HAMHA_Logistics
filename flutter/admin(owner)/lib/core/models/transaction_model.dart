import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';

class TransactionModel {
  final String id;
  final String invoiceNumber;
  final String orderId;
  final String orderCode;
  final String customerName;
  final String customerEmail;
  final String carrierName;
  final String carrierPlate;
  final double grossAmount;
  final double platformCommission; // 15%
  final double gstTax;             // 18% of commission
  final double carrierPayout;       // 85%
  final String paymentStatus;
  final String paymentMethod;
  final String cargoType;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.invoiceNumber,
    required this.orderId,
    required this.orderCode,
    required this.customerName,
    required this.customerEmail,
    required this.carrierName,
    required this.carrierPlate,
    required this.grossAmount,
    required this.platformCommission,
    required this.gstTax,
    required this.carrierPayout,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.cargoType,
    required this.createdAt,
  });

  Color get statusColor {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return AdminTheme.statusOnline; // Green
      case 'pending':
        return const Color(0xFFF59E0B); // Amber
      case 'refunded':
        return AdminTheme.crimsonRed;   // Red
      default:
        return AdminTheme.textMuted;
    }
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final double gross = ((json['gross_amount'] ?? 1000) as num).toDouble();
    final double comm = ((json['platform_commission'] ?? (gross * 0.15)) as num).toDouble();
    final double gst = ((json['gst_tax'] ?? (comm * 0.18)) as num).toDouble();
    final double payout = ((json['carrier_payout'] ?? (gross * 0.85)) as num).toDouble();

    return TransactionModel(
      id: (json['transaction_id'] ?? json['id'] ?? 'TXN-00000').toString(),
      invoiceNumber: (json['invoice_number'] ?? 'INV-HMH-00000').toString(),
      orderId: (json['order_id'] ?? '').toString(),
      orderCode: (json['order_code'] ?? 'HMH-00000').toString(),
      customerName: (json['customer_name'] ?? 'Corporate Client').toString(),
      customerEmail: (json['customer_email'] ?? 'client@corp.com').toString(),
      carrierName: (json['carrier_name'] ?? 'Unassigned').toString(),
      carrierPlate: (json['carrier_plate'] ?? 'N/A').toString(),
      grossAmount: gross,
      platformCommission: comm,
      gstTax: gst,
      carrierPayout: payout,
      paymentStatus: (json['payment_status'] ?? 'paid').toString(),
      paymentMethod: (json['payment_method'] ?? 'UPI Auto-Pay').toString(),
      cargoType: (json['cargo_type'] ?? 'General Freight').toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

