import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../theme/admin_theme.dart';

enum DriverFleetStatus {
  available, // Online & Idle (Green)
  onTrip,    // Active Delivery (Crimson Red)
  offline,   // Disconnected / Off duty (Grey)
}

class FleetDriverModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String vehicleId;
  final String vehicleType; // 'bike', 'van', 'truck'
  final String plateNumber;
  final String vehicleModel;
  final DriverFleetStatus status;
  final LatLng location;
  final double heading;
  final double speedKmh;
  final int batteryPercent;
  final String onlineDuration;
  final String district;
  final String? currentOrderCode;
  final String? currentCargo;
  final String? pickupAddress;
  final String? dropoffAddress;
  final List<LatLng> activeRoute;
  final DateTime lastSeen;

  const FleetDriverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.vehicleId,
    required this.vehicleType,
    required this.plateNumber,
    required this.vehicleModel,
    required this.status,
    required this.location,
    this.heading = 0.0,
    this.speedKmh = 0.0,
    this.batteryPercent = 95,
    this.onlineDuration = '3h 45m',
    this.district = 'Thane District',
    this.currentOrderCode,
    this.currentCargo,
    this.pickupAddress,
    this.dropoffAddress,
    this.activeRoute = const [],
    required this.lastSeen,
  });

  Color get statusColor {
    switch (status) {
      case DriverFleetStatus.available:
        return AdminTheme.statusOnline; // Green (#22C55E)
      case DriverFleetStatus.onTrip:
        return AdminTheme.crimsonRed;   // Crimson Red (#DC2626)
      case DriverFleetStatus.offline:
        return AdminTheme.statusOffline; // Grey (#64748B)
    }
  }

  String get statusLabel {
    switch (status) {
      case DriverFleetStatus.available:
        return 'AVAILABLE / IDLE';
      case DriverFleetStatus.onTrip:
        return 'ON DELIVERY';
      case DriverFleetStatus.offline:
        return 'OFFLINE';
    }
  }

  IconData get vehicleIcon {
    switch (vehicleType.toLowerCase()) {
      case 'bike':
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'van':
      case 'tempo':
        return Icons.local_shipping;
      case 'truck':
      case 'heavy':
        return Icons.fire_truck;
      default:
        return Icons.directions_car;
    }
  }

  String get state {
    final d = district.toLowerCase();
    final p = (pickupAddress ?? '').toLowerCase();
    final dr = (dropoffAddress ?? '').toLowerCase();
    final combined = '$d $p $dr';
    if (combined.contains('karnataka') || combined.contains('bengaluru') || combined.contains('bangalore')) {
      return 'Karnataka';
    }
    if (combined.contains('tamil nadu') || combined.contains('chennai')) {
      return 'Tamil Nadu';
    }
    if (combined.contains('gujarat') || combined.contains('ahmedabad') || combined.contains('surat')) {
      return 'Gujarat';
    }
    if (combined.contains('telangana') || combined.contains('hyderabad')) {
      return 'Telangana';
    }
    if (combined.contains('delhi')) {
      return 'Delhi NCR';
    }
    return 'Maharashtra';
  }

  String get presentDistrict => district.isNotEmpty ? district : 'Thane District';

  FleetDriverModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? vehicleId,
    String? vehicleType,
    String? plateNumber,
    String? vehicleModel,
    DriverFleetStatus? status,
    LatLng? location,
    double? heading,
    double? speedKmh,
    int? batteryPercent,
    String? onlineDuration,
    String? district,
    String? currentOrderCode,
    String? currentCargo,
    String? pickupAddress,
    String? dropoffAddress,
    List<LatLng>? activeRoute,
    DateTime? lastSeen,
  }) {
    return FleetDriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleType: vehicleType ?? this.vehicleType,
      plateNumber: plateNumber ?? this.plateNumber,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      status: status ?? this.status,
      location: location ?? this.location,
      heading: heading ?? this.heading,
      speedKmh: speedKmh ?? this.speedKmh,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      onlineDuration: onlineDuration ?? this.onlineDuration,
      district: district ?? this.district,
      currentOrderCode: currentOrderCode ?? this.currentOrderCode,
      currentCargo: currentCargo ?? this.currentCargo,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      activeRoute: activeRoute ?? this.activeRoute,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  factory FleetDriverModel.fromJson(Map<String, dynamic> json) {
    DriverFleetStatus status = DriverFleetStatus.offline;
    final bool isOnline = json['is_online'] == true || json['isOnline'] == true;
    final bool isAvailable = json['is_available'] == true || json['isAvailable'] == true;

    if (isOnline) {
      status = isAvailable ? DriverFleetStatus.available : DriverFleetStatus.onTrip;
    }

    final double lat = (json['current_lat'] ?? json['latitude'] ?? json['lat'] ?? 19.0760).toDouble();
    final double lon = (json['current_lon'] ?? json['longitude'] ?? json['lng'] ?? 72.8777).toDouble();

    return FleetDriverModel(
      id: (json['driver_id'] ?? json['id'] ?? '').toString(),
      name: (json['driver_name'] ?? json['name'] ?? 'Driver').toString(),
      phone: (json['driver_phone'] ?? json['phone'] ?? '+91 9876543210').toString(),
      email: (json['driver_email'] ?? json['email'] ?? '').toString(),
      vehicleId: (json['vehicle_id'] ?? '').toString(),
      vehicleType: (json['vehicle_type'] ?? 'van').toString(),
      plateNumber: (json['plate_number'] ?? 'MH-04-HM-0000').toString(),
      vehicleModel: (json['vehicle_model'] ?? 'Tata Ace').toString(),
      status: status,
      location: LatLng(lat, lon),
      heading: ((json['heading'] ?? 0.0) as num).toDouble(),
      speedKmh: ((json['speed_kmh'] ?? json['speed'] ?? 0.0) as num).toDouble(),
      batteryPercent: ((json['battery'] ?? 92) as num).toInt(),
      onlineDuration: (json['online_duration'] ?? '4h 15m').toString(),
      district: (json['district'] ?? 'Mumbai Metropolitan Region').toString(),
      currentOrderCode: json['current_order_code']?.toString(),
      currentCargo: json['cargo_type']?.toString(),
      pickupAddress: json['pickup_address']?.toString(),
      dropoffAddress: json['dropoff_address']?.toString(),
      lastSeen: DateTime.tryParse(json['last_location_updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

