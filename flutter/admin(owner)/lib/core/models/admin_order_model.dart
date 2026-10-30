import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../theme/admin_theme.dart';

class AdminOrderModel {
  final String id;
  final String orderCode;
  final String status;
  final String cargoType;
  final double weightKg;
  final String pickupAddress;
  final LatLng pickupLocation;
  final String pickupContactName;
  final String pickupContactPhone;
  final String dropoffAddress;
  final LatLng dropoffLocation;
  final String dropoffContactName;
  final String dropoffContactPhone;
  final double fareAmount;
  final double distanceKm;
  final int estimatedDurationMin;
  final String paymentStatus;
  final String customerName;
  final String customerPhone;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? plateNumber;
  final String? vehicleModel;
  final DateTime createdAt;
  final DateTime? assignedAt;
  final DateTime? deliveredAt;

  const AdminOrderModel({
    required this.id,
    required this.orderCode,
    required this.status,
    required this.cargoType,
    required this.weightKg,
    required this.pickupAddress,
    required this.pickupLocation,
    required this.pickupContactName,
    required this.pickupContactPhone,
    required this.dropoffAddress,
    required this.dropoffLocation,
    required this.dropoffContactName,
    required this.dropoffContactPhone,
    required this.fareAmount,
    required this.distanceKm,
    this.estimatedDurationMin = 45,
    required this.paymentStatus,
    required this.customerName,
    required this.customerPhone,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.plateNumber,
    this.vehicleModel,
    required this.createdAt,
    this.assignedAt,
    this.deliveredAt,
  });

  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B); // Amber
      case 'assigned':
        return const Color(0xFF2563EB); // Royal Blue
      case 'picked_up':
      case 'in_transit':
        return AdminTheme.crimsonRed;   // Crimson Red
      case 'delivered':
        return AdminTheme.statusOnline; // Emerald Green
      case 'cancelled':
        return AdminTheme.statusOffline; // Grey
      default:
        return AdminTheme.textMuted;
    }
  }

  String get statusLabel {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  AdminOrderModel copyWith({
    String? status,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? plateNumber,
    String? vehicleModel,
    DateTime? assignedAt,
  }) {
    return AdminOrderModel(
      id: id,
      orderCode: orderCode,
      status: status ?? this.status,
      cargoType: cargoType,
      weightKg: weightKg,
      pickupAddress: pickupAddress,
      pickupLocation: pickupLocation,
      pickupContactName: pickupContactName,
      pickupContactPhone: pickupContactPhone,
      dropoffAddress: dropoffAddress,
      dropoffLocation: dropoffLocation,
      dropoffContactName: dropoffContactName,
      dropoffContactPhone: dropoffContactPhone,
      fareAmount: fareAmount,
      distanceKm: distanceKm,
      estimatedDurationMin: estimatedDurationMin,
      paymentStatus: paymentStatus,
      customerName: customerName,
      customerPhone: customerPhone,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      plateNumber: plateNumber ?? this.plateNumber,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      createdAt: createdAt,
      assignedAt: assignedAt ?? this.assignedAt,
      deliveredAt: deliveredAt,
    );
  }

  factory AdminOrderModel.fromJson(Map<String, dynamic> json) {
    final double pLat = (json['pickup_lat'] ?? 19.2183).toDouble();
    final double pLon = (json['pickup_lon'] ?? 72.9781).toDouble();
    final double dLat = (json['dropoff_lat'] ?? 19.0760).toDouble();
    final double dLon = (json['dropoff_lon'] ?? 72.8777).toDouble();

    return AdminOrderModel(
      id: (json['id'] ?? '').toString(),
      orderCode: (json['order_code'] ?? 'HMH-00000').toString(),
      status: (json['status'] ?? 'pending').toString(),
      cargoType: (json['cargo_type'] ?? 'General Freight').toString(),
      weightKg: ((json['weight_kg'] ?? 10.0) as num).toDouble(),
      pickupAddress: (json['pickup_address'] ?? 'Thane Hub').toString(),
      pickupLocation: LatLng(pLat, pLon),
      pickupContactName: (json['pickup_contact_name'] ?? 'Warehouse Supervisor').toString(),
      pickupContactPhone: (json['pickup_contact_phone'] ?? '+91 98200 11111').toString(),
      dropoffAddress: (json['dropoff_address'] ?? 'Mumbai Terminal').toString(),
      dropoffLocation: LatLng(dLat, dLon),
      dropoffContactName: (json['dropoff_contact_name'] ?? 'Recipient Dispatch').toString(),
      dropoffContactPhone: (json['dropoff_contact_phone'] ?? '+91 98200 22222').toString(),
      fareAmount: ((json['fare_amount'] ?? 1500) as num).toDouble(),
      distanceKm: ((json['distance_km'] ?? 15.0) as num).toDouble(),
      estimatedDurationMin: ((json['estimated_duration_min'] ?? 40) as num).toInt(),
      paymentStatus: (json['payment_status'] ?? 'paid').toString(),
      customerName: (json['customer_name'] ?? 'Reliance Retail Ltd').toString(),
      customerPhone: (json['customer_phone'] ?? '+91 98111 22334').toString(),
      driverId: json['driver_id']?.toString(),
      driverName: json['driver_name']?.toString(),
      driverPhone: json['driver_phone']?.toString(),
      plateNumber: json['plate_number']?.toString(),
      vehicleModel: json['vehicle_model']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      assignedAt: DateTime.tryParse(json['assigned_at']?.toString() ?? ''),
      deliveredAt: DateTime.tryParse(json['delivered_at']?.toString() ?? ''),
    );
  }
}

