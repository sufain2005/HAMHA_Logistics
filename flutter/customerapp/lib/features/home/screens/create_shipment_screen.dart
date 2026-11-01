import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/quote_model.dart';
import '../../../core/models/owner_corridor_route_model.dart';
import '../../../core/network/api_client.dart';
import '../../tracking/screens/order_tracking_screen.dart';

class CreateShipmentScreen extends StatefulWidget {
  const CreateShipmentScreen({super.key});

  @override
  State<CreateShipmentScreen> createState() => _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends State<CreateShipmentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Cargo & Vehicle
  String _selectedCargo = 'Industrial Equipment';
  String _selectedVehicle = 'van'; // 'bike', 'mini_van', 'van', 'truck', 'heavy_6tire'
  final _weightController = TextEditingController(text: '18.5');
  final _descriptionController = TextEditingController(text: 'Heavy duty boxed components');
  final _otherCargoDescriptionController = TextEditingController();

  // Origin (Pick-up Point) - Real Structured Indian Address
  final _pickupBuildingController = TextEditingController(text: 'Plot 45, Gate 3, Bhiwandi Logistics Park');
  final _pickupStreetController = TextEditingController(text: 'Mumbai-Nashik Highway NH 160');
  final _pickupLandmarkController = TextEditingController(text: 'Near Indian Oil Petrol Pump');
  final _pickupCityController = TextEditingController(text: 'Thane (Mumbai MMR)');
  String _pickupState = 'Maharashtra';
  final _pickupPincodeController = TextEditingController(text: '421302');
  final _pickupSenderNameController = TextEditingController(text: 'Warehouse Dispatch Officer');
  final _pickupSenderPhoneController = TextEditingController(text: '+91 98201 12345');

  // Destination (Drop-off Point) - Real Structured Indian Address
  final _dropoffBuildingController = TextEditingController(text: 'Building B, Unit 302, Whitefield Tech Park');
  final _dropoffStreetController = TextEditingController(text: 'ITPL Main Road');
  final _dropoffLandmarkController = TextEditingController(text: 'Opposite Metro Station Gate 2');
  final _dropoffCityController = TextEditingController(text: 'Bengaluru Urban');
  String _dropoffState = 'Karnataka';
  final _dropoffPincodeController = TextEditingController(text: '560066');
  final _contactNameController = TextEditingController(text: 'Receiving Dock Manager');
  final _contactPhoneController = TextEditingController(text: '+91 98450 99881');

  // Selected Payment Method for Handover
  String _selectedPaymentMethod = 'Cash to Pickup Pilot (Cash on Dispatch)';

  // Coordinates
  double _pickupLon = 73.0544;
  double _pickupLat = 19.2969;
  double _dropoffLon = 77.7499;
  double _dropoffLat = 12.9698;
  double _distanceKm = 145.0;

  QuoteModel? _currentQuote;
  Map<String, dynamic> _adminTariffs = {};
  bool _isCalculating = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Active Owner Corridor Routes (> 20kg & Long-Distance routes)
  List<OwnerCorridorRouteModel> _availableOwnerCorridors = [];
  bool _isLoadingOwnerCorridors = false;
  OwnerCorridorRouteModel? _selectedOwnerRoute;

  bool get _isLongDistanceAndHeavy {
    final w = double.tryParse(_weightController.text.trim()) ?? 0;
    final isLongDist = _distanceKm >= 50.0 ||
        _pickupState != _dropoffState ||
        _pickupCityController.text.trim().toLowerCase() != _dropoffCityController.text.trim().toLowerCase();
    return w > 20.0 && isLongDist;
  }

  final List<String> _indianStates = [
    'Maharashtra',
    'Karnataka',
    'Gujarat',
    'Telangana',
    'Tamil Nadu',
    'Delhi NCR',
    'Uttar Pradesh',
    'Haryana',
    'Rajasthan',
    'Madhya Pradesh',
    'West Bengal',
    'Andhra Pradesh',
  ];

  @override
  void initState() {
    super.initState();
    _loadTariffsAndCalculate();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _descriptionController.dispose();
    _otherCargoDescriptionController.dispose();

    _pickupBuildingController.dispose();
    _pickupStreetController.dispose();
    _pickupLandmarkController.dispose();
    _pickupCityController.dispose();
    _pickupPincodeController.dispose();
    _pickupSenderNameController.dispose();
    _pickupSenderPhoneController.dispose();

    _dropoffBuildingController.dispose();
    _dropoffStreetController.dispose();
    _dropoffLandmarkController.dispose();
    _dropoffCityController.dispose();
    _dropoffPincodeController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadTariffsAndCalculate() async {
    final tariffs = await ApiClient().fetchAdminTariffs();
    if (mounted) {
      setState(() {
        _adminTariffs = tariffs;
      });
      _calculateQuote();
    }
  }

  static const Map<String, List<double>> _cityCoordinates = {
    // Maharashtra
    'thane': [73.0544, 19.2969],
    'mumbai': [72.8777, 19.0760],
    'navi mumbai': [73.0297, 19.0330],
    'bhiwandi': [73.0544, 19.2969],
    'pune': [73.8567, 18.5204],
    'nashik': [73.7898, 19.9975],
    'nagpur': [79.0882, 21.1458],
    'aurangabad': [75.3433, 19.8762],
    'chhatrapati sambhajinagar': [75.3433, 19.8762],
    'kolhapur': [74.2433, 16.7050],
    'solapur': [75.9064, 17.6599],
    // Karnataka
    'bengaluru': [77.5946, 12.9716],
    'bangalore': [77.5946, 12.9716],
    'whitefield': [77.7499, 12.9698],
    'mysuru': [76.6394, 12.2958],
    'hubli': [75.1240, 15.3647],
    'belagavi': [74.4977, 15.8497],
    // Gujarat
    'ahmedabad': [72.5714, 23.0225],
    'sanand': [72.3813, 22.9877],
    'surat': [72.8311, 21.1702],
    'vadodara': [73.1812, 22.3072],
    'rajkot': [70.8022, 22.3039],
    // Telangana & Andhra Pradesh
    'hyderabad': [78.4867, 17.3850],
    'visakhapatnam': [83.2185, 17.6868],
    'vijayawada': [80.6480, 16.5062],
    // Tamil Nadu
    'chennai': [80.2707, 13.0827],
    'coimbatore': [76.9558, 11.0168],
    'madurai': [78.1198, 9.9252],
    // Delhi NCR & North
    'delhi': [77.2090, 28.6139],
    'delhi ncr': [77.2090, 28.6139],
    'gurgaon': [77.0266, 28.4595],
    'noida': [77.3910, 28.5355],
    'faridabad': [77.3178, 28.4089],
    'jaipur': [75.7873, 26.9124],
    'lucknow': [80.9462, 26.8467],
    'kanpur': [80.3319, 26.4499],
    'chandigarh': [76.7794, 30.7333],
    // Central & East
    'indore': [75.8577, 22.7196],
    'bhopal': [77.4126, 23.2599],
    'kolkata': [88.3639, 22.5726],
    'patna': [85.1376, 25.5941],
    'kochi': [76.2673, 9.9312],
  };

  static const Map<String, List<double>> _stateCoordinates = {
    'maharashtra': [73.8567, 18.5204],
    'karnataka': [77.5946, 12.9716],
    'gujarat': [72.5714, 23.0225],
    'telangana': [78.4867, 17.3850],
    'tamil nadu': [80.2707, 13.0827],
    'delhi ncr': [77.2090, 28.6139],
    'uttar pradesh': [80.9462, 26.8467],
    'haryana': [77.0266, 28.4595],
    'rajasthan': [75.7873, 26.9124],
    'madhya pradesh': [77.4126, 23.2599],
    'west bengal': [88.3639, 22.5726],
    'andhra pradesh': [80.6480, 16.5062],
  };

  List<double> _resolveCoordinates(String cityText, String stateText, {required bool isPickup}) {
    final lowerCity = cityText.toLowerCase();
    for (final entry in _cityCoordinates.entries) {
      if (lowerCity.contains(entry.key)) {
        return entry.value;
      }
    }
    final lowerState = stateText.toLowerCase();
    for (final entry in _stateCoordinates.entries) {
      if (lowerState.contains(entry.key)) {
        return entry.value;
      }
    }
    return isPickup ? [73.0544, 19.2969] : [77.7499, 12.9698];
  }

  double _haversineKm(double lon1, double lat1, double lon2, double lat2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * (math.pi / 180.0);
    final dLon = (lon2 - lon1) * (math.pi / 180.0);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180.0)) * math.cos(lat2 * (math.pi / 180.0)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  void _calculateDistance() {
    final pickupCoords = _resolveCoordinates(_pickupCityController.text, _pickupState, isPickup: true);
    final dropoffCoords = _resolveCoordinates(_dropoffCityController.text, _dropoffState, isPickup: false);

    _pickupLon = pickupCoords[0];
    _pickupLat = pickupCoords[1];
    _dropoffLon = dropoffCoords[0];
    _dropoffLat = dropoffCoords[1];

    final pCity = _pickupCityController.text.trim().toLowerCase();
    final dCity = _dropoffCityController.text.trim().toLowerCase();

    // Check if intra-city or identical locations
    final isSameCity = (pCity.isNotEmpty && dCity.isNotEmpty && (pCity.contains(dCity) || dCity.contains(pCity))) &&
        (_pickupState.toLowerCase() == _dropoffState.toLowerCase());

    if (isSameCity) {
      // Dynamic intra-city road distance between 14.0 km and 38.0 km based on address differences
      final addressHash = (_pickupStreetController.text.length + _dropoffStreetController.text.length + _pickupBuildingController.text.length) % 25;
      _distanceKm = 14.0 + addressHash.toDouble();
    } else {
      final straightKm = _haversineKm(_pickupLon, _pickupLat, _dropoffLon, _dropoffLat);
      if (straightKm < 30.0) {
        _distanceKm = math.max(18.0, straightKm * 1.35);
      } else {
        // Inter-city highway road distance (multiplying straight-line by 1.32x for winding road network)
        _distanceKm = math.max(45.0, (straightKm * 1.32).roundToDouble());
      }
    }
  }

  Future<void> _calculateQuote() async {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) return;

    _calculateDistance();

    if (_isLongDistanceAndHeavy) {
      _fetchMatchingOwnerCorridors();
    } else {
      if (_availableOwnerCorridors.isNotEmpty || _selectedOwnerRoute != null) {
        setState(() {
          _availableOwnerCorridors = [];
          _selectedOwnerRoute = null;
        });
      }
    }

    setState(() {
      _isCalculating = true;
      _errorMessage = null;
    });

    try {
      final quote = await ApiClient().calculateQuote(
        weightKg: weight,
        pickupLon: _pickupLon,
        pickupLat: _pickupLat,
        dropoffLon: _dropoffLon,
        dropoffLat: _dropoffLat,
        cargoType: _selectedCargo,
        vehicleType: _selectedVehicle,
        customDistanceKm: _distanceKm,
      );

      setState(() {
        _currentQuote = quote;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isCalculating = false);
    }
  }

  Future<void> _fetchMatchingOwnerCorridors() async {
    final weight = double.tryParse(_weightController.text.trim()) ?? 0;
    if (weight <= 20.0) return;

    setState(() => _isLoadingOwnerCorridors = true);
    try {
      final corridors = await ApiClient().fetchMatchingOwnerCorridors(
        weightKg: weight,
        distanceKm: _distanceKm,
        pickupState: _pickupState,
        pickupCity: _pickupCityController.text.trim(),
        dropoffState: _dropoffState,
        dropoffCity: _dropoffCityController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _availableOwnerCorridors = corridors;
          _isLoadingOwnerCorridors = false;
          if (_selectedOwnerRoute != null && !corridors.any((c) => c.id == _selectedOwnerRoute!.id)) {
            _selectedOwnerRoute = null;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingOwnerCorridors = false);
    }
  }

  String _formatFullAddress({
    required TextEditingController building,
    required TextEditingController street,
    required TextEditingController landmark,
    required TextEditingController city,
    required String state,
    required TextEditingController pincode,
  }) {
    final parts = [
      building.text.trim(),
      street.text.trim(),
      if (landmark.text.trim().isNotEmpty) 'Near ${landmark.text.trim()}',
      city.text.trim(),
      state,
      if (pincode.text.trim().isNotEmpty) 'PIN: ${pincode.text.trim()}',
    ];
    return parts.where((p) => p.isNotEmpty).join(', ');
  }

  Future<void> _handleProceed() async {
    if (!_formKey.currentState!.validate()) return;

    final weight = double.tryParse(_weightController.text.trim()) ?? 10.0;
    final fullPickup = _formatFullAddress(
      building: _pickupBuildingController,
      street: _pickupStreetController,
      landmark: _pickupLandmarkController,
      city: _pickupCityController,
      state: _pickupState,
      pincode: _pickupPincodeController,
    );

    final fullDropoff = _formatFullAddress(
      building: _dropoffBuildingController,
      street: _dropoffStreetController,
      landmark: _dropoffLandmarkController,
      city: _dropoffCityController,
      state: _dropoffState,
      pincode: _dropoffPincodeController,
    );

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final defaultFare = double.tryParse(_currentQuote?.totalFare ?? '3450') ?? 3450.0;
      final fare = _selectedOwnerRoute != null ? _selectedOwnerRoute!.offeredFare : defaultFare;

      final finalCargoType = _selectedCargo == 'Other'
          ? 'Other: ${_otherCargoDescriptionController.text.trim().isEmpty ? "Bike Delivery" : _otherCargoDescriptionController.text.trim()}'
          : _selectedCargo;

      final res = await ApiClient().createOrder(
        cargoType: finalCargoType,
        weightKg: weight,
        packageDescription: _descriptionController.text.trim(),
        pickupAddress: fullPickup,
        pickupLon: _pickupLon,
        pickupLat: _pickupLat,
        dropoffAddress: fullDropoff,
        dropoffLon: _dropoffLon,
        dropoffLat: _dropoffLat,
        dropoffContactName: _contactNameController.text.trim(),
        dropoffContactPhone: _contactPhoneController.text.trim(),
        senderContactName: _pickupSenderNameController.text.trim(),
        senderContactPhone: _pickupSenderPhoneController.text.trim(),
        fareAmount: fare,
        distanceKm: _distanceKm,
        vehicleType: _selectedOwnerRoute != null ? _selectedOwnerRoute!.truckType : _selectedVehicle,
        ownerRequirementId: _selectedOwnerRoute?.id,
        appliedFare: _selectedOwnerRoute?.offeredFare,
        paymentMethod: _selectedPaymentMethod,
        customDistanceKm: _distanceKm,
      );

      if (!mounted) return;

      final newOrderId = res['order']['id'];

      final successMsg = _selectedOwnerRoute != null
          ? 'Shipment booked on Owner Corridor (${_selectedOwnerRoute!.ownerCompany})! Heavy commercial driver dispatch initiated.'
          : 'Shipment booked successfully! Driver dispatch initiated with live GPS tracking.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF059669),
          content: Text(successMsg),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: newOrderId),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HamhaTheme.warmCream,
      appBar: AppBar(
        backgroundColor: HamhaTheme.crispWhite,
        title: const Text(
          'Book New Shipment',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: HamhaTheme.deepBlack),
        ),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: HamhaTheme.deepBlack),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: HamhaTheme.crimsonTint,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: HamhaTheme.crimsonRed),
                      ),
                      child: Text(_errorMessage!, style: const TextStyle(color: HamhaTheme.crimsonDark, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // -----------------------------------------------------------------
                  // SECTION 1: CARGO SPECIFICATIONS & VEHICLE TYPE
                  // -----------------------------------------------------------------
                  _buildSectionCard(
                    title: '1. Package, Weight & Vehicle Class',
                    icon: Icons.inventory_2_outlined,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedCargo,
                        decoration: const InputDecoration(labelText: 'Cargo Category / Commodity Type'),
                        items: const [
                          DropdownMenuItem(value: 'Industrial Equipment', child: Text('Industrial Equipment & Machinery')),
                          DropdownMenuItem(value: 'Medical Supplies', child: Text('Medical Supplies & Pharmaceuticals')),
                          DropdownMenuItem(value: 'Electronics & Hardware', child: Text('Electronics & Computer Hardware')),
                          DropdownMenuItem(value: 'Automotive Spare Parts', child: Text('Automotive Parts & Components')),
                          DropdownMenuItem(value: 'General Commercial Freight', child: Text('General Commercial Freight / FMCG')),
                          DropdownMenuItem(value: 'Heavy Raw Materials', child: Text('Heavy Raw Materials / Metals')),
                          DropdownMenuItem(value: 'Other', child: Text('Other / Custom Parcel (Bike Delivery)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCargo = val;
                              if (val == 'Other') {
                                _selectedVehicle = 'bike';
                                final currentW = double.tryParse(_weightController.text) ?? 0;
                                if (currentW > 20.0 || currentW == 0) {
                                  _weightController.text = '2.5';
                                }
                              }
                            });
                            _calculateQuote();
                          }
                        },
                      ),
                      if (_selectedCargo == 'Other') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _otherCargoDescriptionController,
                          decoration: InputDecoration(
                            labelText: 'Describe Item(s) Sent via Bike',
                            hintText: 'e.g. Tiffin / food delivery, legal documents, spare keys, small parcel',
                            prefixIcon: const Icon(Icons.two_wheeler, color: HamhaTheme.crimsonRed),
                            filled: true,
                            fillColor: HamhaTheme.crimsonTint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: HamhaTheme.crimsonRed.withAlpha(60)),
                            ),
                          ),
                          onChanged: (v) {
                            if (_descriptionController.text.isEmpty || _descriptionController.text == 'Heavy duty boxed components') {
                              _descriptionController.text = v;
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Commercial Vehicle Selection
                      const Text(
                        'REQUIRED TRANSPORT FLEET VEHICLE',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: HamhaTheme.textMuted, letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildVehicleOption('bike', 'Bike (2W)', 'Up to 20kg', Icons.two_wheeler),
                            _buildVehicleOption('mini_van', 'Mini Van', 'Tata Ace (1T)', Icons.airport_shuttle),
                            _buildVehicleOption('van', 'Van (Bolero)', 'Maxi Truck (2T)', Icons.directions_bus),
                            _buildVehicleOption('truck', 'Truck (4T)', 'Eicher Pro', Icons.local_shipping),
                            _buildVehicleOption('heavy_6tire', '6-Tire Multi-Axle', 'Heavy 10T+', Icons.fire_truck),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Consignment Total Weight (in KG)',
                          suffixText: 'KG',
                          helperText: 'Admin rate applies per KG for excess cargo weight',
                        ),
                        validator: (val) => val == null || double.tryParse(val) == null ? 'Enter valid weight in KG' : null,
                        onChanged: (_) => _calculateQuote(),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Package Description / Handling Notes for Driver',
                          hintText: 'e.g. 4 corrugated boxes, handle with care, palletized',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // -----------------------------------------------------------------
                  // SECTION 2: ORIGIN (REAL WHOLE PICK-UP ADDRESS)
                  // -----------------------------------------------------------------
                  _buildSectionCard(
                    title: '2. Origin (Complete Pick-up Address)',
                    icon: Icons.trip_origin,
                    iconColor: HamhaTheme.crimsonRed,
                    children: [
                      // Quick Location Presets for 1-Tap Fill
                      const Text(
                        'QUICK POPULAR HUBS (1-TAP FILL)',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: HamhaTheme.textMuted, letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildPresetChip('Bhiwandi Hub (MH)', () {
                            setState(() {
                              _pickupBuildingController.text = 'Plot 45, Gate 3, Bhiwandi Logistics Park';
                              _pickupStreetController.text = 'Mumbai-Nashik Highway NH 160';
                              _pickupCityController.text = 'Thane';
                              _pickupState = 'Maharashtra';
                              _pickupPincodeController.text = '421302';
                            });
                            _calculateQuote();
                          }),
                          _buildPresetChip('MIDC Navi Mumbai', () {
                            setState(() {
                              _pickupBuildingController.text = 'Plot D-12, Pawane Industrial Area';
                              _pickupStreetController.text = 'Thane-Belapur Road';
                              _pickupCityController.text = 'Navi Mumbai';
                              _pickupState = 'Maharashtra';
                              _pickupPincodeController.text = '400705';
                            });
                            _calculateQuote();
                          }),
                          _buildPresetChip('BKC Mumbai', () {
                            setState(() {
                              _pickupBuildingController.text = 'Platina Tower, G-Block';
                              _pickupStreetController.text = 'Bandra Kurla Complex Link Road';
                              _pickupCityController.text = 'Mumbai';
                              _pickupState = 'Maharashtra';
                              _pickupPincodeController.text = '400051';
                            });
                            _calculateQuote();
                          }),
                        ],
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _pickupBuildingController,
                        decoration: const InputDecoration(
                          labelText: 'Warehouse / Building / Flat / Plot Number',
                          hintText: 'e.g. Plot 45, Gate 3, Bhiwandi Logistics Park',
                          prefixIcon: Icon(Icons.home_work_outlined, color: HamhaTheme.crimsonRed),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Building/Plot required' : null,
                        onChanged: (_) => _calculateQuote(),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _pickupStreetController,
                        decoration: const InputDecoration(
                          labelText: 'Street / Road / Highway / Industrial Area',
                          hintText: 'e.g. Mumbai-Nashik Highway NH 160',
                          prefixIcon: Icon(Icons.add_road, color: HamhaTheme.textMuted),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Street/Highway required' : null,
                        onChanged: (_) => _calculateQuote(),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _pickupLandmarkController,
                              decoration: const InputDecoration(
                                labelText: 'Landmark',
                                hintText: 'e.g. Near Indian Oil Petrol Pump',
                              ),
                              onChanged: (_) => _calculateQuote(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _pickupCityController,
                              decoration: const InputDecoration(
                                labelText: 'City / District',
                                hintText: 'e.g. Thane / Mumbai MMR',
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'City required' : null,
                              onChanged: (_) => _calculateQuote(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              value: _pickupState,
                              decoration: const InputDecoration(labelText: 'State'),
                              items: _indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _pickupState = val);
                                  _calculateQuote();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _pickupPincodeController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: const InputDecoration(
                                labelText: 'Pincode (6 digits)',
                                hintText: '421302',
                                counterText: '',
                              ),
                              validator: (val) => val == null || val.length != 6 ? '6-digit PIN' : null,
                              onChanged: (_) => _calculateQuote(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Contact Person at Pickup
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _pickupSenderNameController,
                              decoration: const InputDecoration(
                                labelText: 'Sender / Dispatcher Name',
                                prefixIcon: Icon(Icons.person_outline, size: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _pickupSenderPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Sender Mobile Number (+91)',
                                prefixIcon: Icon(Icons.phone_android, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // -----------------------------------------------------------------
                  // SECTION 3: DESTINATION (REAL WHOLE DROP-OFF ADDRESS)
                  // -----------------------------------------------------------------
                  _buildSectionCard(
                    title: '3. Destination (Complete Drop-off Address)',
                    icon: Icons.flag_outlined,
                    iconColor: HamhaTheme.deepBlack,
                    children: [
                      // Quick Dropoff Presets
                      const Text(
                        'QUICK POPULAR DESTINATIONS (1-TAP FILL)',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: HamhaTheme.textMuted, letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildPresetChip('Whitefield Bengaluru', () {
                            setState(() {
                              _dropoffBuildingController.text = 'Building B, Unit 302, Whitefield Tech Park';
                              _dropoffStreetController.text = 'ITPL Main Road';
                              _dropoffCityController.text = 'Bengaluru Urban';
                              _dropoffState = 'Karnataka';
                              _dropoffPincodeController.text = '560066';
                            });
                            _calculateQuote();
                          }),
                          _buildPresetChip('Pune Hinjewadi Hub', () {
                            setState(() {
                              _dropoffBuildingController.text = 'Phase 2, Quadron Business Park';
                              _dropoffStreetController.text = 'Hinjewadi IT Park Road';
                              _dropoffCityController.text = 'Pune';
                              _dropoffState = 'Maharashtra';
                              _dropoffPincodeController.text = '411057';
                            });
                            _calculateQuote();
                          }),
                          _buildPresetChip('GIDC Ahmedabad', () {
                            setState(() {
                              _dropoffBuildingController.text = 'Shed 104, Sanand Industrial Estate';
                              _dropoffStreetController.text = 'Sanand-Viramgam Highway';
                              _dropoffCityController.text = 'Ahmedabad';
                              _dropoffState = 'Gujarat';
                              _dropoffPincodeController.text = '382110';
                            });
                            _calculateQuote();
                          }),
                        ],
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _dropoffBuildingController,
                        decoration: const InputDecoration(
                          labelText: 'Warehouse / Building / Unit Number',
                          hintText: 'e.g. Building B, Unit 302, Whitefield Tech Park',
                          prefixIcon: Icon(Icons.domain, color: HamhaTheme.deepBlack),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Building required' : null,
                        onChanged: (_) => _calculateQuote(),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _dropoffStreetController,
                        decoration: const InputDecoration(
                          labelText: 'Street / Area / Industrial Corridor',
                          hintText: 'e.g. ITPL Main Road',
                          prefixIcon: Icon(Icons.add_road, color: HamhaTheme.textMuted),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Street required' : null,
                        onChanged: (_) => _calculateQuote(),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _dropoffLandmarkController,
                              decoration: const InputDecoration(
                                labelText: 'Landmark',
                                hintText: 'e.g. Opposite Metro Station Gate 2',
                              ),
                              onChanged: (_) => _calculateQuote(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _dropoffCityController,
                              decoration: const InputDecoration(
                                labelText: 'City / District',
                                hintText: 'e.g. Bengaluru Urban',
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'City required' : null,
                              onChanged: (_) => _calculateQuote(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              value: _dropoffState,
                              decoration: const InputDecoration(labelText: 'State'),
                              items: _indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _dropoffState = val);
                                  _calculateQuote();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _dropoffPincodeController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: const InputDecoration(
                                labelText: 'Pincode (6 digits)',
                                hintText: '560066',
                                counterText: '',
                              ),
                              validator: (val) => val == null || val.length != 6 ? '6-digit PIN' : null,
                              onChanged: (_) => _calculateQuote(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _contactNameController,
                              decoration: const InputDecoration(
                                labelText: 'Receiver Name',
                                prefixIcon: Icon(Icons.person_outline, size: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _contactPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Receiver Mobile (+91)',
                                prefixIcon: Icon(Icons.phone_android, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // -----------------------------------------------------------------
                  // SECTION 4: REAL-TIME TARIFF BREAKDOWN STRICTLY BY ADMIN PRICING
                  // -----------------------------------------------------------------
                  _buildTariffBreakdownCard(),
                  const SizedBox(height: 20),

                  // -----------------------------------------------------------------
                  // SECTION 5: OWNER ADDED CORRIDOR ROUTES (>20KG & LONG DISTANCE)
                  // -----------------------------------------------------------------
                  _buildOwnerCorridorsSection(),
                  const SizedBox(height: 20),

                  // -----------------------------------------------------------------
                  // SECTION 6: CONSIGNMENT PAYMENT MODE (CASH / PILOT QR / ONLINE)
                  // -----------------------------------------------------------------
                  _buildPaymentMethodSection(),
                  const SizedBox(height: 24),

                  // Booking CTA Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleProceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HamhaTheme.crimsonRed,
                      foregroundColor: HamhaTheme.crispWhite,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_selectedOwnerRoute != null ? Icons.verified_user : Icons.local_shipping, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                _selectedOwnerRoute != null
                                    ? 'CONFIRM & BOOK OWNER ROUTE (₹${_selectedOwnerRoute!.offeredFare.toStringAsFixed(0)} INR)'
                                    : 'CONFIRM & BOOK SHIPMENT (₹${_currentQuote?.totalFare ?? "---"} INR)',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.6),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    Color iconColor = HamhaTheme.textDark,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HamhaTheme.crispWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HamhaTheme.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: HamhaTheme.deepBlack,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: HamhaTheme.borderSubtle),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildVehicleOption(String type, String title, String subtitle, IconData icon) {
    final isSelected = _selectedVehicle == type;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          setState(() => _selectedVehicle = type);
          _calculateQuote();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? HamhaTheme.crimsonRed : HamhaTheme.warmCream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? HamhaTheme.crimsonRed : HamhaTheme.borderSubtle),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.white : HamhaTheme.deepBlack),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : HamhaTheme.deepBlack),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 9, color: isSelected ? Colors.white70 : HamhaTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
      backgroundColor: HamhaTheme.warmCream,
      side: const BorderSide(color: HamhaTheme.borderSubtle),
      onPressed: onTap,
    );
  }

  Widget _buildTariffBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HamhaTheme.crispWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HamhaTheme.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.calculate_outlined, color: HamhaTheme.crimsonRed, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'FREIGHT TARIFF BREAKDOWN',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: HamhaTheme.deepBlack, letterSpacing: 0.3),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SYNCED WITH ADMIN PRICING',
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: HamhaTheme.borderSubtle),
          const SizedBox(height: 14),

          if (_isCalculating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: HamhaTheme.crimsonRed, strokeWidth: 2),
              ),
            )
          else ...[
            _buildCostLine('Estimated Distance:', '${_distanceKm.toStringAsFixed(1)} KM (Highway Route)'),
            _buildCostLine('Vehicle Class:', _selectedVehicle.replaceAll('_', ' ').toUpperCase()),
            _buildCostLine('Base Consignment Fee:', _currentQuote?.breakdown['baseFee'] ?? '₹350'),
            _buildCostLine('Distance Fare (${_distanceKm.toStringAsFixed(0)} KM):', _currentQuote?.breakdown['distanceRate'] ?? '---'),
            _buildCostLine('Weight Charge:', _currentQuote?.breakdown['weightSurcharge'] ?? '₹0'),
            _buildCostLine(
              'Statutory GST (18%):',
              _currentQuote?.breakdown['gstTax'] ??
                  _currentQuote?.breakdown['gst'] ??
                  (_currentQuote != null ? '₹${((_currentQuote!.fareAmount * 0.18) / 1.18).round()}' : '₹0'),
            ),
            if (_selectedOwnerRoute != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: HamhaTheme.crimsonRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: HamhaTheme.crimsonRed.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: HamhaTheme.crimsonRed, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Owner Corridor Rate Applied: ${_selectedOwnerRoute!.ownerCompany} (${_selectedOwnerRoute!.truckTypeDisplayName})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: HamhaTheme.crimsonRed),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1, color: HamhaTheme.borderSubtle),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Estimated Consignment Fare', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: HamhaTheme.deepBlack)),
                    Text('Includes GST, toll corridor, and driver compensation', style: TextStyle(fontSize: 10, color: HamhaTheme.textMuted)),
                  ],
                ),
                Text(
                  _selectedOwnerRoute != null
                      ? '₹${_selectedOwnerRoute!.offeredFare.toStringAsFixed(0)} INR'
                      : '₹${_currentQuote?.totalFare ?? "---"} INR',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: HamhaTheme.crimsonRed),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOwnerCorridorsSection() {
    if (!_isLongDistanceAndHeavy) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HamhaTheme.crispWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _selectedOwnerRoute != null ? HamhaTheme.crimsonRed : HamhaTheme.borderSubtle,
          width: _selectedOwnerRoute != null ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _selectedOwnerRoute != null
                ? HamhaTheme.crimsonRed.withAlpha(20)
                : Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: HamhaTheme.crimsonRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.alt_route, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Available Fleet Owner Routes',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: HamhaTheme.deepBlack,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: HamhaTheme.crimsonRed.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '> 20 KG CORRIDOR',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: HamhaTheme.crimsonRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Long-distance inter-district/state corridor detected. Click an owner\'s active route to book directly with guaranteed fleet capacity.',
                      style: TextStyle(fontSize: 11.5, color: HamhaTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoadingOwnerCorridors)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: HamhaTheme.crimsonRed, strokeWidth: 2)),
            )
          else if (_availableOwnerCorridors.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: HamhaTheme.warmCream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: HamhaTheme.borderSubtle),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: HamhaTheme.textMuted, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No direct fleet owner route broadcast active on this exact corridor right now. Your consignment will be fulfilled via dynamic regional commercial carrier dispatch.',
                      style: TextStyle(fontSize: 11.5, color: HamhaTheme.textMuted),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _availableOwnerCorridors.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final route = _availableOwnerCorridors[index];
                final isSelected = _selectedOwnerRoute?.id == route.id;

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedOwnerRoute = null;
                      } else {
                        _selectedOwnerRoute = route;
                        _selectedVehicle = route.truckType;
                      }
                    });
                    _calculateQuote();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? HamhaTheme.crimsonRed.withAlpha(15) : HamhaTheme.warmCream,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? HamhaTheme.crimsonRed : HamhaTheme.borderSubtle,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? HamhaTheme.crimsonRed : Colors.white,
                            border: Border.all(
                              color: isSelected ? HamhaTheme.crimsonRed : HamhaTheme.borderSubtle,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      route.ownerCompany,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: HamhaTheme.deepBlack,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected ? HamhaTheme.crimsonRed : HamhaTheme.deepBlack,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '₹${route.offeredFare.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.route, size: 14, color: HamhaTheme.crimsonRed),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      route.routeCorridorText,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: HamhaTheme.deepBlack,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                children: [
                                  Text(
                                    '🚚 ${route.truckTypeDisplayName}',
                                    style: const TextStyle(fontSize: 10.5, color: HamhaTheme.textMuted),
                                  ),
                                  Text(
                                    '⚖️ ${route.weightTons}T (${(route.weightTons * 1000).toStringAsFixed(0)} kg capacity)',
                                    style: const TextStyle(fontSize: 10.5, color: HamhaTheme.textMuted),
                                  ),
                                  Text(
                                    '⏳ ${route.remainingTimeFormatted}',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? HamhaTheme.crimsonRed : HamhaTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              if (isSelected) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: HamhaTheme.crimsonRed,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '✓ APPLIED TO THIS SHIPMENT (CLICK AGAIN TO DESELECT)',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCostLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: HamhaTheme.textMuted, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontSize: 12, color: HamhaTheme.deepBlack, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HamhaTheme.crispWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HamhaTheme.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment, color: HamhaTheme.crimsonRed, size: 20),
              SizedBox(width: 8),
              Text(
                'SELECT CONSIGNMENT PAYMENT MODE',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: HamhaTheme.deepBlack, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: HamhaTheme.borderSubtle),
          const SizedBox(height: 14),

          _buildPaymentRadioTile(
            title: 'Cash to Pickup Pilot (Cash on Dispatch)',
            subtitle: 'Pay physical cash to the driver upon consignment collection at pickup address',
            icon: Icons.payments_outlined,
            value: 'Cash to Pickup Pilot (Cash on Dispatch)',
          ),
          const SizedBox(height: 10),

          _buildPaymentRadioTile(
            title: 'Direct Driver UPI QR Code (Scan Pilot QR)',
            subtitle: 'Pilot will show their personalized HAMHA UPI QR code at pickup for instant phone scan',
            icon: Icons.qr_code_scanner,
            value: 'Direct Driver UPI QR Code (Scan Pilot QR)',
          ),
          const SizedBox(height: 10),

          _buildPaymentRadioTile(
            title: 'Online Advance (UPI / Net Banking / Card)',
            subtitle: 'Instant digital prepayment with automated GST invoice generation',
            icon: Icons.account_balance,
            value: 'Online UPI / Corporate Net Banking',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRadioTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? HamhaTheme.crimsonRed.withAlpha(15) : HamhaTheme.warmCream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? HamhaTheme.crimsonRed : HamhaTheme.borderSubtle,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? HamhaTheme.crimsonRed : HamhaTheme.deepBlack,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? HamhaTheme.crimsonRed : HamhaTheme.deepBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10.5, color: HamhaTheme.textMuted),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              activeColor: HamhaTheme.crimsonRed,
              onChanged: (val) {
                if (val != null) setState(() => _selectedPaymentMethod = val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
