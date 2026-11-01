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

  /// Generates a standardized custom Driver ID following the specification:
  /// - First 4 digits: Present year (e.g. 2026)
  /// - Next 3 digits: First 3 digits of registered phone number (e.g. 807, 982)
  /// - Next 5 digits: Sequential padded number starting 00000, 00001, 00002...
  /// - Last characters: Initials of the driver's name (e.g. Jaykaanth Shikree -> JS)
  /// Example: 202680700001JS
  String get customDriverId {
    final year = DateTime.now().year.toString();

    // Extract raw digits from phone number (stripping country code +91 or non-digits)
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    String phonePrefix = '807';
    if (digitsOnly.length >= 12 && digitsOnly.startsWith('91')) {
      phonePrefix = digitsOnly.substring(2, 5);
    } else if (digitsOnly.length >= 10) {
      phonePrefix = digitsOnly.substring(0, 3);
    } else if (digitsOnly.length >= 3) {
      phonePrefix = digitsOnly.substring(0, 3);
    }

    // Next 5 digits: padded sequential index (deterministic based on driver id or sequence)
    int seqNum = 1;
    final idDigits = id.replaceAll(RegExp(r'\D'), '');
    if (idDigits.length >= 5) {
      final parsed = int.tryParse(idDigits.substring(idDigits.length - 5));
      if (parsed != null && parsed >= 0) seqNum = parsed % 100000;
    } else if (idDigits.isNotEmpty) {
      seqNum = (int.tryParse(idDigits) ?? 1) % 100000;
    }
    final seqStr = seqNum.toString().padLeft(5, '0');

    // Initials of name (first letter of each word in driver's name, uppercase)
    final nameParts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    String initials = '';
    for (final part in nameParts) {
      initials += part[0].toUpperCase();
    }
    if (initials.isEmpty) initials = 'D';

    return '$year$phonePrefix$seqStr$initials';
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
