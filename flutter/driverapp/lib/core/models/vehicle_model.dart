enum VehicleCategory { bike, van, truck }

class VehicleModel {
  final VehicleCategory category;
  final String title;
  final String description;
  final String maxCapacityKg;
  final String plateNumber;
  final String modelName;

  VehicleModel({
    required this.category,
    required this.title,
    required this.description,
    required this.maxCapacityKg,
    this.plateNumber = '',
    this.modelName = '',
  });

  static List<VehicleModel> get defaults => [
    VehicleModel(
      category: VehicleCategory.bike,
      title: 'Motorcycle / Express Bike',
      description: 'Ideal for quick documents, parcels & high-speed city courier dispatch',
      maxCapacityKg: '30 KG Payload',
    ),
    VehicleModel(
      category: VehicleCategory.van,
      title: 'Delivery Cargo Van',
      description: 'Optimized for commercial cartons, crates, appliances & palletized goods',
      maxCapacityKg: '1,200 KG Payload',
    ),
    VehicleModel(
      category: VehicleCategory.truck,
      title: 'Heavy Freight Multi-Axle Truck',
      description: 'Designed for inter-district heavy industrial machinery & bulk cargo',
      maxCapacityKg: '8,500 KG Payload',
    ),
  ];
}

