class TransitCheckpoint {
  final String location;
  final String district;
  final String state;
  final String timestamp;
  final bool isCompleted;

  TransitCheckpoint({
    required this.location,
    required this.district,
    required this.state,
    required this.timestamp,
    required this.isCompleted,
  });

  factory TransitCheckpoint.fromJson(Map<String, dynamic> json) {
    return TransitCheckpoint(
      location: json['location'] ?? '',
      district: json['district'] ?? '',
      state: json['state'] ?? '',
      timestamp: json['timestamp'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'location': location,
    'district': district,
    'state': state,
    'timestamp': timestamp,
    'isCompleted': isCompleted,
  };
}

class OrderModel {
  final String id;
  final String orderCode;
  final String status;
  final String cargoType;
  final double weightKg;
  final String? packageDescription;
  final String pickupAddress;
  final double pickupLon;
  final double pickupLat;
  final String dropoffAddress;
  final double dropoffLon;
  final double dropoffLat;
  final double fareAmount;
  final String currency;
  final double distanceKm;
  final int? estimatedDurationMin;
  final String paymentStatus;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? vehiclePlate;
  final String? vehicleModel;
  final double? driverLon;
  final double? driverLat;
  final double? driverHeading;
  final double? driverSpeedKmh;
  final String? currentDistrict;
  final String? currentState;
  final String? currentLandmark;
  final String? expectedReachTime;
  final List<TransitCheckpoint> checkpoints;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.orderCode,
    required this.status,
    required this.cargoType,
    required this.weightKg,
    this.packageDescription,
    required this.pickupAddress,
    required this.pickupLon,
    required this.pickupLat,
    required this.dropoffAddress,
    required this.dropoffLon,
    required this.dropoffLat,
    required this.fareAmount,
    this.currency = 'INR',
    required this.distanceKm,
    this.estimatedDurationMin,
    required this.paymentStatus,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.vehiclePlate,
    this.vehicleModel,
    this.driverLon,
    this.driverLat,
    this.driverHeading,
    this.driverSpeedKmh,
    this.currentDistrict,
    this.currentState,
    this.currentLandmark,
    this.expectedReachTime,
    this.checkpoints = const [],
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    List<TransitCheckpoint> parsedCheckpoints = [];
    if (json['checkpoints'] != null && json['checkpoints'] is List) {
      parsedCheckpoints = (json['checkpoints'] as List)
          .map((c) => TransitCheckpoint.fromJson(c))
          .toList();
    }

    return OrderModel(
      id: json['id'] ?? '',
      orderCode: json['order_code'] ?? '',
      status: json['status'] ?? 'pending',
      cargoType: json['cargo_type'] ?? 'General Freight',
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,
      packageDescription: json['package_description'],
      pickupAddress: json['pickup_address'] ?? '',
      pickupLon: (json['pickup_lon'] as num?)?.toDouble() ?? 73.8567,
      pickupLat: (json['pickup_lat'] as num?)?.toDouble() ?? 18.5204,
      dropoffAddress: json['dropoff_address'] ?? '',
      dropoffLon: (json['dropoff_lon'] as num?)?.toDouble() ?? 77.5946,
      dropoffLat: (json['dropoff_lat'] as num?)?.toDouble() ?? 12.9716,
      fareAmount: (json['fare_amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'INR',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      estimatedDurationMin: json['estimated_duration_min'],
      paymentStatus: json['payment_status'] ?? 'pending',
      driverId: json['driver_id'],
      driverName: json['driver_name'],
      driverPhone: json['driver_phone'],
      vehiclePlate: json['plate_number'],
      vehicleModel: json['vehicle_model'],
      driverLon: (json['driver_lon'] as num?)?.toDouble(),
      driverLat: (json['driver_lat'] as num?)?.toDouble(),
      driverHeading: (json['driver_heading'] as num?)?.toDouble(),
      driverSpeedKmh: (json['driver_speed_kmh'] as num?)?.toDouble(),
      currentDistrict: json['current_district'],
      currentState: json['current_state'],
      currentLandmark: json['current_landmark'],
      expectedReachTime: json['expected_reach_time'],
      checkpoints: parsedCheckpoints,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_code': orderCode,
    'status': status,
    'cargo_type': cargoType,
    'weight_kg': weightKg,
    'package_description': packageDescription,
    'pickup_address': pickupAddress,
    'pickup_lon': pickupLon,
    'pickup_lat': pickupLat,
    'dropoff_address': dropoffAddress,
    'dropoff_lon': dropoffLon,
    'dropoff_lat': dropoffLat,
    'fare_amount': fareAmount,
    'currency': currency,
    'distance_km': distanceKm,
    'estimated_duration_min': estimatedDurationMin,
    'payment_status': paymentStatus,
    'driver_id': driverId,
    'driver_name': driverName,
    'driver_phone': driverPhone,
    'plate_number': vehiclePlate,
    'vehicle_model': vehicleModel,
    'driver_lon': driverLon,
    'driver_lat': driverLat,
    'driver_heading': driverHeading,
    'driver_speed_kmh': driverSpeedKmh,
    'current_district': currentDistrict,
    'current_state': currentState,
    'current_landmark': currentLandmark,
    'expected_reach_time': expectedReachTime,
    'checkpoints': checkpoints.map((c) => c.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
  };
}
