import 'package:flutter/material.dart';

class OwnerTruckRequirementModel {
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
  final DateTime postedAt;
  final DateTime expiresAt;
  final int remainingSeconds;
  final String status;

  const OwnerTruckRequirementModel({
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
    required this.postedAt,
    required this.expiresAt,
    required this.remainingSeconds,
    this.status = 'active',
  });

  factory OwnerTruckRequirementModel.fromJson(Map<String, dynamic> json) {
    final posted = json['posted_at'] != null ? DateTime.tryParse(json['posted_at']) ?? DateTime.now() : DateTime.now();
    final expires = json['expires_at'] != null ? DateTime.tryParse(json['expires_at']) ?? posted.add(const Duration(days: 3)) : posted.add(const Duration(days: 3));
    final remSecs = (json['remaining_seconds'] as num?)?.toInt() ?? expires.difference(DateTime.now()).inSeconds;

    return OwnerTruckRequirementModel(
      id: json['id']?.toString() ?? '',
      ownerId: json['owner_id']?.toString() ?? '',
      ownerName: json['owner_name'] ?? 'Fleet Owner',
      ownerCompany: json['owner_company'] ?? 'HAMHA Logistics Partner',
      ownerPhone: json['owner_phone'] ?? '+919820012345',
      ownerWhatsapp: json['owner_whatsapp'] ?? json['owner_phone'] ?? '+919820012345',
      truckType: json['truck_type'] ?? 'box_truck',
      title: json['title'] ?? 'Truck Required for Freight Consignment',
      cargoType: json['cargo_type'] ?? 'General Cargo',
      weightTons: (json['weight_tons'] as num?)?.toDouble() ?? 5.0,
      pickupState: json['pickup_state'] ?? 'Maharashtra',
      pickupCity: json['pickup_city'] ?? 'Mumbai',
      pickupAddress: json['pickup_address'] ?? 'Pickup Logistics Depot',
      dropoffState: json['dropoff_state'] ?? 'Maharashtra',
      dropoffCity: json['dropoff_city'] ?? 'Pune',
      dropoffAddress: json['dropoff_address'] ?? 'Dropoff Warehouse Hub',
      offeredFare: (json['offered_fare'] as num?)?.toDouble() ?? 15000.0,
      currency: json['currency'] ?? 'INR',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 150.0,
      validityDays: (json['validity_days'] as num?)?.toInt() ?? 3,
      postedAt: posted,
      expiresAt: expires,
      remainingSeconds: remSecs > 0 ? remSecs : 0,
      status: json['status'] ?? 'active',
    );
  }

  String get remainingTimeFormatted {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h left';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m left';
    } else {
      return '${minutes}m left';
    }
  }

  Color get urgencyColor {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return const Color(0xFF64748B);
    if (diff.inHours > 48) return const Color(0xFF10B981);
    if (diff.inHours > 24) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }

  String get truckTypeDisplayName {
    switch (truckType.toLowerCase()) {
      case 'box_truck':
        return 'Box Truck';
      case 'mini_truck':
      case 'van':
        return 'Tata Ace / Mini Van';
      case 'heavy_freight':
        return 'Heavy Multi-Axle (10/12-Tire)';
      case 'trailer':
        return 'Articulated Trailer';
      default:
        return 'Commercial Freight Truck';
    }
  }

  static List<OwnerTruckRequirementModel> sampleOwnerRequirements() {
    final now = DateTime.now();
    return [
      OwnerTruckRequirementModel(
        id: 'REQ-MH-101',
        ownerId: 'own-001',
        ownerName: 'Vikram Singhania',
        ownerCompany: 'Singhania National Freight Corp',
        ownerPhone: '+919820012345',
        ownerWhatsapp: '+919820012345',
        truckType: 'box_truck',
        title: 'Require 10-Ton Closed Box Truck for FMCG Consignment',
        cargoType: 'Packaged FMCG & Dairy Products',
        weightTons: 8.5,
        pickupState: 'Maharashtra',
        pickupCity: 'Bhiwandi',
        pickupAddress: 'Bhiwandi Logistics Park, Depot 4B, Thane',
        dropoffState: 'Maharashtra',
        dropoffCity: 'Pune',
        dropoffAddress: 'Chakan Industrial Phase II, Pune MIDC',
        offeredFare: 18500.0,
        currency: 'INR',
        distanceKm: 158.0,
        validityDays: 3,
        postedAt: now.subtract(const Duration(hours: 6)),
        expiresAt: now.add(const Duration(days: 2, hours: 18)),
        remainingSeconds: (const Duration(days: 2, hours: 18)).inSeconds,
      ),
      OwnerTruckRequirementModel(
        id: 'REQ-MH-102',
        ownerId: 'own-001',
        ownerName: 'Vikram Singhania',
        ownerCompany: 'Singhania National Freight Corp',
        ownerPhone: '+919820012345',
        ownerWhatsapp: '+919820012345',
        truckType: 'heavy_freight',
        title: 'Immediate Need: 16-Tire Multi-Axle for Automobile Components',
        cargoType: 'Automobile Engine Blocks & Chassis Parts',
        weightTons: 14.0,
        pickupState: 'Maharashtra',
        pickupCity: 'Navi Mumbai',
        pickupAddress: 'JNPT Port Container Freight Station Gate 2, Uran',
        dropoffState: 'Maharashtra',
        dropoffCity: 'Nashik',
        dropoffAddress: 'Ambad Industrial Area, Nashik MIDC',
        offeredFare: 26500.0,
        currency: 'INR',
        distanceKm: 195.0,
        validityDays: 3,
        postedAt: now.subtract(const Duration(hours: 14)),
        expiresAt: now.add(const Duration(days: 2, hours: 10)),
        remainingSeconds: (const Duration(days: 2, hours: 10)).inSeconds,
      ),
    ];
  }
}
