import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/quote_model.dart';
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

  void _calculateDistance() {
    // Determine realistic road distance between regions
    if (_pickupState == _dropoffState) {
      if (_pickupCityController.text.toLowerCase().contains(_dropoffCityController.text.toLowerCase())) {
        _distanceKm = 24.5; // Intra-city
      } else {
        _distanceKm = 165.0; // Inter-district same state
      }
    } else {
      _distanceKm = 890.0; // Inter-state corridor (e.g. MH to KA)
    }
  }

  Future<void> _calculateQuote() async {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) return;

    _calculateDistance();

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
      final fare = double.tryParse(_currentQuote?.totalFare ?? '3450') ?? 3450.0;

      final res = await ApiClient().createOrder(
        cargoType: _selectedCargo,
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
        vehicleType: _selectedVehicle,
      );

      if (!mounted) return;

      final newOrderId = res['order']['id'];

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF059669),
          content: Text('Shipment booked successfully! Driver dispatch initiated with live GPS tracking.'),
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
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCargo = val);
                            _calculateQuote();
                          }
                        },
                      ),
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
                              const Icon(Icons.local_shipping, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'CONFIRM & BOOK SHIPMENT (₹${_currentQuote?.totalFare ?? "---"} INR)',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calculate_outlined, color: HamhaTheme.crimsonRed, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'TRANSPARENT FREIGHT TARIFF BREAKDOWN',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: HamhaTheme.deepBlack, letterSpacing: 0.6),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SYNCED WITH ADMIN PRICING',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
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
            _buildCostLine('Statutory GST (18%):', _currentQuote?.breakdown['gst'] ?? '---'),
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
                  '₹${_currentQuote?.totalFare ?? "---"} INR',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: HamhaTheme.crimsonRed),
                ),
              ],
            ),
          ],
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    Color iconColor = HamhaTheme.crimsonRed,
    required List<Widget> children,
  }) {
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
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: HamhaTheme.deepBlack),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: HamhaTheme.borderSubtle),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
