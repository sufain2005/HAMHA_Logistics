class DriverCompletedOrderModel {
  final String id;
  final String orderCode;
  final String cargoType;
  final double weightKg;
  final String pickupAddress;
  final String pickupDistrict;
  final String dropoffAddress;
  final String dropoffDistrict;
  final double fareEarned;
  final String currency;
  final double distanceKm;
  final String completedAt;
  final String recipientName;
  final double rating;
  final String podImage;

  const DriverCompletedOrderModel({
    required this.id,
    required this.orderCode,
    required this.cargoType,
    required this.weightKg,
    required this.pickupAddress,
    required this.pickupDistrict,
    required this.dropoffAddress,
    required this.dropoffDistrict,
    required this.fareEarned,
    this.currency = 'INR',
    required this.distanceKm,
    required this.completedAt,
    required this.recipientName,
    this.rating = 5.0,
    this.podImage = 'pod_receipt_verified.jpg',
  });

  factory DriverCompletedOrderModel.fromJson(Map<String, dynamic> json) {
    return DriverCompletedOrderModel(
      id: json['id'] ?? '',
      orderCode: json['order_code'] ?? '',
      cargoType: json['cargo_type'] ?? 'General Cargo',
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 10.0,
      pickupAddress: json['pickup_address'] ?? '',
      pickupDistrict: json['pickup_district'] ?? 'Thane',
      dropoffAddress: json['dropoff_address'] ?? '',
      dropoffDistrict: json['dropoff_district'] ?? 'Mumbai',
      fareEarned: (json['fare_earned'] as num?)?.toDouble() ?? 500.0,
      currency: json['currency'] ?? 'INR',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 15.0,
      completedAt: json['completed_at'] ?? 'Today, 02:45 PM',
      recipientName: json['recipient_name'] ?? 'Warehouse Receiving Desk',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      podImage: json['pod_image'] ?? 'pod_receipt_verified.jpg',
    );
  }

  static List<DriverCompletedOrderModel> sampleCompletedOrders() {
    return const [
      DriverCompletedOrderModel(
        id: 'ord-cmp-01',
        orderCode: 'HMH-31045',
        cargoType: 'Medical Diagnostic Supplies',
        weightKg: 8.5,
        pickupAddress: 'Cipla Depot, Thane Belapur Rd, Navi Mumbai',
        pickupDistrict: 'Thane District',
        dropoffAddress: 'P.D. Hinduja National Hospital, Mahim, Mumbai',
        dropoffDistrict: 'Mumbai City',
        fareEarned: 950.0,
        currency: 'INR',
        distanceKm: 28.4,
        completedAt: 'Today, 04:15 PM',
        recipientName: 'Dr. S. Kulkarni (Pharmacy Stores)',
        rating: 5.0,
      ),
      DriverCompletedOrderModel(
        id: 'ord-cmp-02',
        orderCode: 'HMH-49210',
        cargoType: 'Industrial Hydraulic Bearings',
        weightKg: 42.0,
        pickupAddress: 'Godown 12, Kalamboli Steel Yard, Navi Mumbai',
        pickupDistrict: 'Raigad District',
        dropoffAddress: 'Siemens Precision Plant, Airoli MIDC, Navi Mumbai',
        dropoffDistrict: 'Thane District',
        fareEarned: 1250.0,
        currency: 'INR',
        distanceKm: 19.8,
        completedAt: 'Today, 01:20 PM',
        recipientName: 'G. Deshmukh (Inward Logistics)',
        rating: 5.0,
      ),
      DriverCompletedOrderModel(
        id: 'ord-cmp-03',
        orderCode: 'HMH-88231',
        cargoType: 'High-Value Server Components',
        weightKg: 15.2,
        pickupAddress: 'DHL Express Logistics Centre, Andheri East, Mumbai',
        pickupDistrict: 'Mumbai Suburban',
        dropoffAddress: 'Nesco IT Park, Goregaon East, Mumbai',
        dropoffDistrict: 'Mumbai Suburban',
        fareEarned: 650.0,
        currency: 'INR',
        distanceKm: 9.6,
        completedAt: 'Today, 10:45 AM',
        recipientName: 'Amit Verma (Data Operations)',
        rating: 4.8,
      ),
      DriverCompletedOrderModel(
        id: 'ord-cmp-04',
        orderCode: 'HMH-77192',
        cargoType: 'Textile Rolls & Garments',
        weightKg: 110.0,
        pickupAddress: 'Bhiwandi Textile Complex, Kasheli, Thane',
        pickupDistrict: 'Thane District',
        dropoffAddress: 'Phoenix Palladium Retail Hub, Lower Parel, Mumbai',
        dropoffDistrict: 'Mumbai City',
        fareEarned: 1400.0,
        currency: 'INR',
        distanceKm: 34.2,
        completedAt: 'Yesterday, 06:30 PM',
        recipientName: 'Kunal Mehra (Inventory Lead)',
        rating: 5.0,
      ),
    ];
  }
}

