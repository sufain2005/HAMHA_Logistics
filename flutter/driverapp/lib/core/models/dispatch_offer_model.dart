class DispatchOfferModel {
  final String id;
  final String orderCode;
  final String cargoType;
  final double weightKg;
  final String pickupAddress;
  final String pickupDistrict;
  final double pickupLon;
  final double pickupLat;
  final String dropoffAddress;
  final String dropoffDistrict;
  final double dropoffLon;
  final double dropoffLat;
  final double payoutAmount;
  final String currency;
  final double distanceKm;
  final int estimatedDurationMin;
  final int expiresInSeconds;

  const DispatchOfferModel({
    required this.id,
    required this.orderCode,
    required this.cargoType,
    required this.weightKg,
    required this.pickupAddress,
    required this.pickupDistrict,
    required this.pickupLon,
    required this.pickupLat,
    required this.dropoffAddress,
    required this.dropoffDistrict,
    required this.dropoffLon,
    required this.dropoffLat,
    required this.payoutAmount,
    this.currency = 'INR',
    required this.distanceKm,
    required this.estimatedDurationMin,
    this.expiresInSeconds = 15,
  });

  factory DispatchOfferModel.fromJson(Map<String, dynamic> json) {
    return DispatchOfferModel(
      id: json['id'] ?? 'ord-demo-01',
      orderCode: json['order_code'] ?? 'HMH-89241',
      cargoType: json['cargo_type'] ?? 'Industrial Electronics',
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 38.5,
      pickupAddress: json['pickup_address'] ?? 'Godown 4, Bhiwandi Logistics Corridor, Thane',
      pickupDistrict: json['pickup_district'] ?? 'Thane',
      pickupLon: (json['pickup_lon'] as num?)?.toDouble() ?? 73.0483,
      pickupLat: (json['pickup_lat'] as num?)?.toDouble() ?? 19.2813,
      dropoffAddress: json['dropoff_address'] ?? 'Tower B, Bandra Kurla Complex (BKC), Mumbai',
      dropoffDistrict: json['dropoff_district'] ?? 'Mumbai Suburban',
      dropoffLon: (json['dropoff_lon'] as num?)?.toDouble() ?? 72.8679,
      dropoffLat: (json['dropoff_lat'] as num?)?.toDouble() ?? 19.0657,
      payoutAmount: (json['payout_amount'] as num?)?.toDouble() ?? 1850.0,
      currency: json['currency'] ?? 'INR',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 24.6,
      estimatedDurationMin: json['estimated_duration_min'] ?? 42,
      expiresInSeconds: json['expires_in_seconds'] ?? 15,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_code': orderCode,
    'cargo_type': cargoType,
    'weight_kg': weightKg,
    'pickup_address': pickupAddress,
    'pickup_district': pickupDistrict,
    'pickup_lon': pickupLon,
    'pickup_lat': pickupLat,
    'dropoff_address': dropoffAddress,
    'dropoff_district': dropoffDistrict,
    'dropoff_lon': dropoffLon,
    'dropoff_lat': dropoffLat,
    'payout_amount': payoutAmount,
    'currency': currency,
    'distance_km': distanceKm,
    'estimated_duration_min': estimatedDurationMin,
    'expires_in_seconds': expiresInSeconds,
  };

  static DispatchOfferModel sampleBhiwandiMumbaiOffer() {
    return const DispatchOfferModel(
      id: 'ord-bhiwandi-bkc-101',
      orderCode: 'HMH-89241',
      cargoType: 'Industrial Electronics & Spares',
      weightKg: 38.5,
      pickupAddress: 'Godown 4, Bhiwandi Logistics Corridor, Thane',
      pickupDistrict: 'Thane, Maharashtra',
      pickupLon: 73.0483,
      pickupLat: 19.2813,
      dropoffAddress: 'Tower B, Bandra Kurla Complex (BKC), Mumbai',
      dropoffDistrict: 'Mumbai Suburban, Maharashtra',
      dropoffLon: 72.8679,
      dropoffLat: 19.0657,
      payoutAmount: 1850.0,
      currency: 'INR',
      distanceKm: 24.6,
      estimatedDurationMin: 42,
      expiresInSeconds: 15,
    );
  }
}

