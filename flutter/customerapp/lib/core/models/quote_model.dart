class QuoteModel {
  final String cargoType;
  final double weightKg;
  final double distanceKm;
  final int estimatedDurationMin;
  final String currency;
  final String totalFare;
  final Map<String, dynamic> breakdown;

  QuoteModel({
    required this.cargoType,
    required this.weightKg,
    required this.distanceKm,
    required this.estimatedDurationMin,
    this.currency = 'INR',
    required this.totalFare,
    required this.breakdown,
  });

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    return QuoteModel(
      cargoType: json['cargoType'] ?? 'Standard Cargo',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      estimatedDurationMin: json['estimatedDurationMin'] ?? 0,
      currency: json['currency'] ?? 'INR',
      totalFare: json['totalFare']?.toString() ?? '0',
      breakdown: json['breakdown'] ?? {},
    );
  }
}
