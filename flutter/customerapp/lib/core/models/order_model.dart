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
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      orderCode: json['order_code'] ?? '',
      status: json['status'] ?? 'pending',
      cargoType: json['cargo_type'] ?? 'General Freight',
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,
      packageDescription: json['package_description'],
      pickupAddress: json['pickup_address'] ?? '',
      pickupLon: (json['pickup_lon'] as num?)?.toDouble() ?? -122.4022,
      pickupLat: (json['pickup_lat'] as num?)?.toDouble() ?? 37.7758,
      dropoffAddress: json['dropoff_address'] ?? '',
      dropoffLon: (json['dropoff_lon'] as num?)?.toDouble() ?? -122.4005,
      dropoffLat: (json['dropoff_lat'] as num?)?.toDouble() ?? 37.7858,
      fareAmount: (json['fare_amount'] as num?)?.toDouble() ?? 0.0,
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
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

