import 'package:flutter/material.dart';

class TruckRequirementModel {
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

  const TruckRequirementModel({
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

  factory TruckRequirementModel.fromJson(Map<String, dynamic> json) {
    final posted = json['posted_at'] != null ? DateTime.tryParse(json['posted_at']) ?? DateTime.now() : DateTime.now();
    final expires = json['expires_at'] != null ? DateTime.tryParse(json['expires_at']) ?? posted.add(const Duration(days: 3)) : posted.add(const Duration(days: 3));
    final remSecs = (json['remaining_seconds'] as num?)?.toInt() ?? expires.difference(DateTime.now()).inSeconds;

    return TruckRequirementModel(
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
      return '${minutes}m left (Urgent)';
    }
  }

  Color get urgencyColor {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return const Color(0xFF64748B);
    if (diff.inHours > 48) return const Color(0xFF10B981); // Green (> 2 days)
    if (diff.inHours > 24) return const Color(0xFFF59E0B); // Amber (1-2 days)
    return const Color(0xFFDC2626); // Crimson (< 24 hours)
  }

  String get truckTypeDisplayName {
    switch (truckType.toLowerCase()) {
      case 'box_truck':
        return 'Box Truck';
      case 'mini_truck':
      case 'van':
        return 'Tata Ace / Mini Van';
      case 'heavy_freight':
        return 'Heavy Freight (10/12-Tire)';
      case 'trailer':
        return 'Articulated Trailer';
      case 'motorcycle':
        return 'Cargo 2-Wheeler';
      default:
        return 'Commercial Freight Truck';
    }
  }

  IconData get truckIcon {
    switch (truckType.toLowerCase()) {
      case 'heavy_freight':
      case 'trailer':
        return Icons.fire_truck;
      case 'box_truck':
        return Icons.local_shipping;
      case 'van':
      case 'mini_truck':
        return Icons.airport_shuttle;
      default:
        return Icons.local_shipping;
    }
  }

  static List<TruckRequirementModel> sampleRequirements(String state) {
    final now = DateTime.now();
    return [
      TruckRequirementModel(
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
        pickupState: state,
        pickupCity: state == 'Maharashtra' ? 'Bhiwandi' : 'Central Logistics Hub',
        pickupAddress: state == 'Maharashtra' ? 'Bhiwandi Logistics Park, Depot 4B, Thane' : 'Industrial Depot Sector 5',
        dropoffState: state,
        dropoffCity: state == 'Maharashtra' ? 'Pune' : 'Regional MIDC Complex',
        dropoffAddress: state == 'Maharashtra' ? 'Chakan Industrial Phase II, Pune MIDC' : 'Consignee Central Godown',
        offeredFare: 18500.0,
        currency: 'INR',
        distanceKm: 158.0,
        validityDays: 3,
        postedAt: now.subtract(const Duration(hours: 6)),
        expiresAt: now.add(const Duration(days: 2, hours: 18)),
        remainingSeconds: (const Duration(days: 2, hours: 18)).inSeconds,
      ),
      TruckRequirementModel(
        id: 'REQ-MH-102',
        ownerId: 'own-002',
        ownerName: 'Manish Agarwal',
        ownerCompany: 'Trans-India Logistics Network',
        ownerPhone: '+919833344556',
        ownerWhatsapp: '+919833344556',
        truckType: 'heavy_freight',
        title: 'Immediate Need: 16-Tire Multi-Axle for Automobile Components',
        cargoType: 'Automobile Engine Blocks & Chassis Parts',
        weightTons: 14.0,
        pickupState: state,
        pickupCity: state == 'Maharashtra' ? 'Navi Mumbai' : 'Container Freight Station',
        pickupAddress: state == 'Maharashtra' ? 'JNPT Port Container Freight Station Gate 2, Uran' : 'Port CFS Terminal A',
        dropoffState: state,
        dropoffCity: state == 'Maharashtra' ? 'Nashik' : 'Auto Cluster MIDC',
        dropoffAddress: state == 'Maharashtra' ? 'Ambad Industrial Area, Nashik MIDC' : 'Manufacturing Plant Bay 3',
        offeredFare: 26500.0,
        currency: 'INR',
        distanceKm: 195.0,
        validityDays: 3,
        postedAt: now.subtract(const Duration(hours: 14)),
        expiresAt: now.add(const Duration(days: 2, hours: 10)),
        remainingSeconds: (const Duration(days: 2, hours: 10)).inSeconds,
      ),
      TruckRequirementModel(
        id: 'REQ-MH-103',
        ownerId: 'own-003',
        ownerName: 'Rajendra Joshi',
        ownerCompany: 'Apex Cold-Chain Solutions',
        ownerPhone: '+919811122334',
        ownerWhatsapp: '+919811122334',
        truckType: 'van',
        title: 'Urgent Van Required for Temperature Controlled Pharma Delivery',
        cargoType: 'Life-Saving Diagnostic Reagents & Vaccines',
        weightTons: 1.8,
        pickupState: state,
        pickupCity: state == 'Maharashtra' ? 'Mumbai' : 'Airport Cargo Depot',
        pickupAddress: state == 'Maharashtra' ? 'Andheri East Cargo Complex, Airport Road, Mumbai' : 'Pharma Cold Storage Gate 1',
        dropoffState: state,
        dropoffCity: state == 'Maharashtra' ? 'Kolhapur' : 'District Medical Depot',
        dropoffAddress: state == 'Maharashtra' ? 'Shiroli MIDC Central Cold Hub, Kolhapur' : 'Government Hospital Receiving Store',
        offeredFare: 14200.0,
        currency: 'INR',
        distanceKm: 380.0,
        validityDays: 3,
        postedAt: now.subtract(const Duration(hours: 22)),
        expiresAt: now.add(const Duration(days: 2, hours: 2)),
        remainingSeconds: (const Duration(days: 2, hours: 2)).inSeconds,
      ),
      TruckRequirementModel(
        id: 'REQ-MH-104',
        ownerId: 'own-004',
        ownerName: 'Harpreet Singh Sandhu',
        ownerCompany: 'Sher-E-Punjab Heavy Haulers',
        ownerPhone: '+919877788990',
        ownerWhatsapp: '+919877788990',
        truckType: 'box_truck',
        title: 'Interstate Freight: 8-Ton Truck for Textile Machinery Parts',
        cargoType: 'Precision Weaving Loom Components',
        weightTons: 7.2,
        pickupState: state,
        pickupCity: state == 'Maharashtra' ? 'Thane' : 'Engineering Zone',
        pickupAddress: state == 'Maharashtra' ? 'Wagle Industrial Estate, Road No 16, Thane West' : 'Machinery Hub Warehouse 8',
        dropoffState: 'Gujarat',
        dropoffCity: 'Surat',
        dropoffAddress: 'Sachin GIDC Textile Processing Park, Surat',
        offeredFare: 22000.0,
        currency: 'INR',
        distanceKm: 285.0,
        validityDays: 3,
        postedAt: now.subtract(const Duration(days: 1, hours: 4)),
        expiresAt: now.add(const Duration(days: 1, hours: 20)),
        remainingSeconds: (const Duration(days: 1, hours: 20)).inSeconds,
      ),
    ];
  }
}

