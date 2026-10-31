import 'package:flutter/material.dart';

class OwnerCorridorRouteModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String ownerCompany;
  final String ownerPhone;
  final String ownerWhatsapp;
  final String truckType;
  final String title;
  final String cargoType;
  final double weightTons;
  final String pickupState;
  final String pickupCity;
  final String pickupAddress;
  final String dropoffState;
  final String dropoffCity;
  final String dropoffAddress;
  final double offeredFare;
  final String currency;
  final double distanceKm;
  final int validityDays;
  final int remainingSeconds;
  final int remainingHours;
  final DateTime? expiresAt;

  const OwnerCorridorRouteModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerCompany,
    required this.ownerPhone,
    required this.ownerWhatsapp,
    required this.truckType,
    required this.title,
    required this.cargoType,
    required this.weightTons,
    required this.pickupState,
    required this.pickupCity,
    required this.pickupAddress,
    required this.dropoffState,
    required this.dropoffCity,
    required this.dropoffAddress,
    required this.offeredFare,
    this.currency = 'INR',
    required this.distanceKm,
    this.validityDays = 3,
    required this.remainingSeconds,
    required this.remainingHours,
    this.expiresAt,
  });

  factory OwnerCorridorRouteModel.fromJson(Map<String, dynamic> json) {
    return OwnerCorridorRouteModel(
      id: json['id']?.toString() ?? '',
      ownerId: json['owner_id']?.toString() ?? '',
      ownerName: json['owner_name']?.toString() ?? 'HAMHA Fleet Owner',
      ownerCompany: json['owner_company']?.toString() ?? 'Verified National Logistics',
      ownerPhone: json['owner_phone']?.toString() ?? '',
      ownerWhatsapp: json['owner_whatsapp']?.toString() ?? json['owner_phone']?.toString() ?? '',
      truckType: json['truck_type']?.toString() ?? 'box_truck',
      title: json['title']?.toString() ?? 'Fleet Corridor Transit Route',
      cargoType: json['cargo_type']?.toString() ?? 'General Freight',
      weightTons: (json['weight_tons'] as num?)?.toDouble() ?? 5.0,
      pickupState: json['pickup_state']?.toString() ?? '',
      pickupCity: json['pickup_city']?.toString() ?? '',
      pickupAddress: json['pickup_address']?.toString() ?? '',
      dropoffState: json['dropoff_state']?.toString() ?? '',
      dropoffCity: json['dropoff_city']?.toString() ?? '',
      dropoffAddress: json['dropoff_address']?.toString() ?? '',
      offeredFare: (json['offered_fare'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'INR',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 150.0,
      validityDays: (json['validity_days'] as num?)?.toInt() ?? 3,
      remainingSeconds: (json['remaining_seconds'] as num?)?.toInt() ?? 259200,
      remainingHours: (json['remaining_hours'] as num?)?.toInt() ?? 72,
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'].toString()) : null,
    );
  }

  String get truckTypeDisplayName {
    switch (truckType.toLowerCase()) {
      case 'box_truck':
        return 'Heavy Box Truck (10T)';
      case 'flatbed':
        return 'Open Flatbed Carrier';
      case 'trailer':
        return 'Multi-Axle Trailer (24T)';
      case 'container_20ft':
        return '20ft ISO Shipping Container';
      case 'container_40ft':
        return '40ft High-Cube Container';
      case 'refrigerated':
        return 'Refrigerated Reefer Truck';
      case 'mini_truck':
        return 'Tata Ace / 4-Wheeler';
      case 'heavy_6tire':
        return '6-Tyre Heavy Commercial (14T)';
      case 'heavy_10tire':
        return '10-Tyre Heavy Hauler (20T)';
      default:
        return 'Commercial Freight Truck';
    }
  }

  String get remainingTimeFormatted {
    if (remainingSeconds <= 0) return 'Expired';
    final days = remainingHours ~/ 24;
    final hours = remainingHours % 24;
    if (days > 0) {
      return '${days}d ${hours}h left';
    }
    final mins = (remainingSeconds % 3600) ~/ 60;
    return '${hours}h ${mins}m left';
  }

  String get routeCorridorText => '$pickupCity ($pickupState) ➔ $dropoffCity ($dropoffState)';
}

