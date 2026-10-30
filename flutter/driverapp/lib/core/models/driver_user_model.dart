class DriverUserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final bool isVerified;
  final bool isOnline;
  final bool isOnboarded;
  final String? vehicleType;
  final String? plateNumber;
  final String? vehicleModel;
  final double rating;
  final double todayEarnings;
  final int todayTrips;
  final String onlineHours;

  DriverUserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.isVerified = true,
    this.isOnline = false,
    this.isOnboarded = true,
    this.vehicleType = 'Van',
    this.plateNumber = 'MH 12 AB 1234',
    this.vehicleModel = 'Tata Ace Gold 1.5T',
    this.rating = 4.9,
    this.todayEarnings = 3450.0,
    this.todayTrips = 6,
    this.onlineHours = '5h 20m',
  });

  factory DriverUserModel.fromJson(Map<String, dynamic> json) {
    return DriverUserModel(
      id: json['id'] ?? 'drv-partner-01',
      name: json['name'] ?? 'Rajesh Kumar',
      phone: json['phone'] ?? '+91 98234 11209',
      email: json['email'] ?? 'driver@hamha.com',
      isVerified: json['is_verified'] ?? true,
      isOnline: json['is_online'] ?? false,
      isOnboarded: json['is_onboarded'] ?? true,
      vehicleType: json['vehicle_type'] ?? 'Van',
      plateNumber: json['plate_number'] ?? 'MH 12 AB 1234',
      vehicleModel: json['vehicle_model'] ?? 'Tata Ace Gold 1.5T',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
      todayEarnings: (json['today_earnings'] as num?)?.toDouble() ?? 3450.0,
      todayTrips: json['today_trips'] ?? 6,
      onlineHours: json['online_hours'] ?? '5h 20m',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'is_verified': isVerified,
    'is_online': isOnline,
    'is_onboarded': isOnboarded,
    'vehicle_type': vehicleType,
    'plate_number': plateNumber,
    'vehicle_model': vehicleModel,
    'rating': rating,
    'today_earnings': todayEarnings,
    'today_trips': todayTrips,
    'online_hours': onlineHours,
  };
}
