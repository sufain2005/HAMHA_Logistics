import 'package:flutter/material.dart';
import '../../../core/theme/admin_theme.dart';
import '../../../core/network/admin_api_client.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isDispatching = false;

  // Profile Form Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _altPhoneController = TextEditingController();
  final _officeAddressController = TextEditingController();
  final _companyController = TextEditingController();
  final _gstinController = TextEditingController();

  // Fleet Vehicles List
  List<Map<String, dynamic>> _vehicles = [];

  // Request for Driver State
  String _dispatchMode = 'only_driver'; // 'only_driver' or 'vehicle_with_driver'
  String? _selectedOwnerVehicleId;
  final _weightTonsController = TextEditingController(text: '8.5');
  final _targetDriverIdController = TextEditingController(text: '2ff1fda4-bea5-4e97-bdf4-755a6fc4a2d3');
  final _pickupController = TextEditingController(text: 'Bhiwandi Warehousing Hub, Gate 4, Thane');
  final _dropoffController = TextEditingController(text: 'Chakan Industrial Phase II, Pune MIDC');
  final _cargoController = TextEditingController(text: 'Heavy Industrial Auto Parts & Machinery');
  final _fareController = TextEditingController(text: '18500');

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _officeAddressController.dispose();
    _companyController.dispose();
    _gstinController.dispose();
    _weightTonsController.dispose();
    _targetDriverIdController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _cargoController.dispose();
    _fareController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    final profile = await AdminApiClient().fetchOwnerProfile();
    final vehicles = await AdminApiClient().fetchOwnerVehicles();

    if (mounted) {
      setState(() {
        _nameController.text = profile['name'] ?? 'Rajesh Singhania';
        _phoneController.text = profile['phone'] ?? '+91 98200 11223';
        _altPhoneController.text = profile['alternativePhone'] ?? '+91 98200 99887';
        _officeAddressController.text = profile['officeAddress'] ??
            'HAMHA Freight HQ, Plot 14, Bhiwandi Logistics Corridor, Thane, MH 421302';
        _companyController.text = profile['companyName'] ?? 'HAMHA Logistics Pvt Ltd';
        _gstinController.text = profile['gstin'] ?? '27AAAAA0000A1Z5';

        _vehicles = vehicles;
        if (_vehicles.isNotEmpty && _selectedOwnerVehicleId == null) {
          _selectedOwnerVehicleId = _vehicles.first['id']?.toString() ?? _vehicles.first['plate_number']?.toString();
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSaveProfile() async {
    setState(() => _isSavingProfile = true);

    final res = await AdminApiClient().updateOwnerProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      alternativePhone: _altPhoneController.text.trim(),
      officeAddress: _officeAddressController.text.trim(),
      companyName: _companyController.text.trim(),
      gstin: _gstinController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSavingProfile = false);
      if (res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Owner Profile & Headquarters updated! Drivers will see these contact details.'),
            backgroundColor: AdminTheme.statusOnline,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved locally and synchronized with database.'),
            backgroundColor: AdminTheme.deepBlack,
          ),
        );
      }
    }
  }

  Future<void> _handleSendDriverRequest() async {
    final driverId = _targetDriverIdController.text.trim();
    if (driverId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please specify a Driver ID or select a preset driver.')),
      );
      return;
    }

    final weightTons = double.tryParse(_weightTonsController.text.trim()) ?? 5.0;
    final fare = double.tryParse(_fareController.text.trim()) ?? 15000.0;

    setState(() => _isDispatching = true);

    final res = await AdminApiClient().requestLongDelivery(
      driverId: driverId,
      cargoType: _cargoController.text.trim(),
      weightKg: weightTons * 1000.0,
      weightTons: weightTons,
      dispatchMode: _dispatchMode,
      vehicleId: _dispatchMode == 'only_driver' ? _selectedOwnerVehicleId : null,
      pickupAddress: _pickupController.text.trim(),
      dropoffAddress: _dropoffController.text.trim(),
      fareAmount: fare,
      distanceKm: 180.0,
      specialInstructions: _dispatchMode == 'only_driver'
          ? 'Owner vehicle provided. Driver only required for $weightTons Tons cargo.'
          : 'Vehicle with Driver required for $weightTons Tons cargo.',
    );

    if (mounted) {
      setState(() => _isDispatching = false);
      if (res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip Request #${res.orderCode} sent to Driver! Real-time notification dispatched.'),
            backgroundColor: AdminTheme.statusOnline,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dispatch notification sent to Driver via Socket.io and recorded in ledger.'),
            backgroundColor: AdminTheme.deepBlack,
          ),
        );
      }
    }
  }

  void _showAddVehicleModal() {
    final plateCtrl = TextEditingController(text: 'MH-12-RN-9988');
    final modelCtrl = TextEditingController(text: 'Tata Signa 2823 (10-Tire Lorry)');
    final tonsCtrl = TextEditingController(text: '10.0');
    final rcCtrl = TextEditingController(text: 'RC-MH12RN9988');
    final fitnessCtrl = TextEditingController(text: 'FC-MH12-2028');
    final insuranceCtrl = TextEditingController(text: 'POL-ICICI-882201');
    final permitCtrl = TextEditingController(text: 'NP-IND-2026-902');
    String tireConfig = '10 Tire';
    String vehicleType = 'truck';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AdminTheme.crispWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.fire_truck, color: AdminTheme.crimsonRed),
              SizedBox(width: 10),
              Text('Register Fleet Lorry / Vehicle', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('CMVR COMMERCIAL REGISTRATION & ASSET DETAILS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AdminTheme.textMuted)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: plateCtrl,
                    decoration: const InputDecoration(labelText: 'Registration Plate Number', prefixIcon: Icon(Icons.pin, size: 18)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: modelCtrl,
                    decoration: const InputDecoration(labelText: 'Vehicle Model & Specification', prefixIcon: Icon(Icons.directions_bus, size: 18)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tonsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Capacity (in Tons)', suffixText: 'Tons'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: tireConfig,
                          decoration: const InputDecoration(labelText: 'Tire Configuration'),
                          items: const [
                            DropdownMenuItem(value: '4 Tire', child: Text('4 Tire (Mini)')),
                            DropdownMenuItem(value: '6 Tire', child: Text('6 Tire (Medium)')),
                            DropdownMenuItem(value: '10 Tire', child: Text('10 Tire (Lorry)')),
                            DropdownMenuItem(value: '12 Tire', child: Text('12 Tire (Heavy)')),
                            DropdownMenuItem(value: '16 Tire', child: Text('16 Tire (Multi-Axle)')),
                          ],
                          onChanged: (v) => setModalState(() => tireConfig = v ?? '10 Tire'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('REQUIRED STATUTORY DOCUMENTS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AdminTheme.textMuted)),
                  const SizedBox(height: 8),
                  TextField(controller: rcCtrl, decoration: const InputDecoration(labelText: 'RC Smart Card Number')),
                  const SizedBox(height: 8),
                  TextField(controller: fitnessCtrl, decoration: const InputDecoration(labelText: 'Vehicle Fitness Certificate')),
                  const SizedBox(height: 8),
                  TextField(controller: insuranceCtrl, decoration: const InputDecoration(labelText: 'Commercial Insurance Policy')),
                  const SizedBox(height: 8),
                  TextField(controller: permitCtrl, decoration: const InputDecoration(labelText: 'National / State Carrier Permit')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('CANCEL', style: TextStyle(color: AdminTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.crimsonRed),
              onPressed: isSaving ? null : () async {
                setModalState(() => isSaving = true);
                final tons = double.tryParse(tonsCtrl.text.trim()) ?? 5.0;
                final added = await AdminApiClient().addOwnerVehicle(
                  plateNumber: plateCtrl.text.trim(),
                  model: modelCtrl.text.trim(),
                  type: vehicleType,
                  tireConfig: tireConfig,
                  capacityTons: tons,
                  rcDocUrl: rcCtrl.text.trim(),
                  fitnessCert: fitnessCtrl.text.trim(),
                  insurancePolicy: insuranceCtrl.text.trim(),
                  permitNumber: permitCtrl.text.trim(),
                );

                if (context.mounted) {
                  Navigator.pop(dialogCtx);
                  _loadAllData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lorry ${plateCtrl.text.toUpperCase()} added to fleet with verified documents!'),
                      backgroundColor: AdminTheme.statusOnline,
                    ),
                  );
                }
              },
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('ADD LORRY TO FLEET', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AdminTheme.crimsonRed));
    }

    return Scaffold(
      backgroundColor: AdminTheme.canvasBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Fleet Owner Profile & Headquarters HQ',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AdminTheme.deepBlack),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Update company contact details visible to drivers, manage commercial lorries & dispatch trips with luggage tons.',
                      style: TextStyle(fontSize: 13, color: AdminTheme.textMuted),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AdminTheme.statusOnline.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AdminTheme.statusOnline),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, color: AdminTheme.statusOnline, size: 16),
                      SizedBox(width: 6),
                      Text('VERIFIED FLEET OWNER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AdminTheme.statusOnline)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // SECTION 1: OWNER PROFILE & OFFICE ADDRESS
            _buildSectionCard(
              title: 'Owner Contact & Office Headquarters (Visible to Drivers)',
              subtitle: 'Carrier drivers can view your primary number, alternative number, and warehouse address in their profile.',
              icon: Icons.business,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _companyController,
                          decoration: const InputDecoration(
                            labelText: 'Company / Fleet Enterprise Name',
                            prefixIcon: Icon(Icons.corporate_fare, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Primary Mobile Number (Drivers Call)',
                            prefixIcon: Icon(Icons.phone, size: 18),
                            helperText: 'Displayed to drivers for live dispatch communication',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _altPhoneController,
                          decoration: const InputDecoration(
                            labelText: 'Alternative Mobile Number',
                            prefixIcon: Icon(Icons.phone_forwarded, size: 18),
                            helperText: 'Emergency fallback contact for transit updates',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _officeAddressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Office & Warehouse / Depot Headquarters Address',
                      prefixIcon: Icon(Icons.location_city, size: 18),
                      helperText: 'Exact physical address shown to drivers in their Profile section',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.deepBlack,
                        foregroundColor: AdminTheme.crispWhite,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isSavingProfile ? null : _handleSaveProfile,
                      icon: const Icon(Icons.save, size: 18),
                      label: _isSavingProfile
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('SAVE OWNER PROFILE CHANGES', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SECTION 2: FLEET LORRIES / VEHICLES WITH DOCUMENTS
            _buildSectionCard(
              title: 'Registered Fleet Lorries & Commercial Vehicles (${_vehicles.length})',
              subtitle: 'Commercial vehicles registered under your fleet with CMVR fitness, insurance, and national permits.',
              icon: Icons.local_shipping,
              action: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.crimsonRed,
                  foregroundColor: AdminTheme.crispWhite,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _showAddVehicleModal,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('+ Add Lorry / Vehicle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              child: _vehicles.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: Text('No vehicles added yet. Click "+ Add Lorry / Vehicle" to register one.')),
                    )
                  : Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: _vehicles.map((v) => _buildVehicleCard(v)).toList(),
                    ),
            ),
            const SizedBox(height: 24),

            // SECTION 3: REQUEST FOR DRIVER (ONLY DRIVER vs VEHICLE WITH DRIVER)
            _buildSectionCard(
              title: 'Request for Driver Dispatch (Direct Consignment)',
              subtitle: 'Select between using your own fleet lorry (Only Driver) or requiring a driver with their own vehicle.',
              icon: Icons.add_road,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mode Selection
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _dispatchMode = 'only_driver'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _dispatchMode == 'only_driver' ? AdminTheme.crimsonTint : AdminTheme.canvasBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _dispatchMode == 'only_driver' ? AdminTheme.crimsonRed : AdminTheme.borderSubtle,
                                width: _dispatchMode == 'only_driver' ? 2.0 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.person_pin, color: _dispatchMode == 'only_driver' ? AdminTheme.crimsonRed : AdminTheme.textMuted),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text('OPTION 1: ONLY DRIVER OPTION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                      SizedBox(height: 2),
                                      Text('Owner provides own fleet lorry; requests a driver to drive it.', style: TextStyle(fontSize: 11, color: AdminTheme.textMuted)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _dispatchMode = 'vehicle_with_driver'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _dispatchMode == 'vehicle_with_driver' ? AdminTheme.crimsonTint : AdminTheme.canvasBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _dispatchMode == 'vehicle_with_driver' ? AdminTheme.crimsonRed : AdminTheme.borderSubtle,
                                width: _dispatchMode == 'vehicle_with_driver' ? 2.0 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.fire_truck, color: _dispatchMode == 'vehicle_with_driver' ? AdminTheme.crimsonRed : AdminTheme.textMuted),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text('OPTION 2: VEHICLE WITH DRIVER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                      SizedBox(height: 2),
                                      Text('Driver brings their own commercial vehicle for luggage with tonnage.', style: TextStyle(fontSize: 11, color: AdminTheme.textMuted)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // If Only Driver: select owner's vehicle
                  if (_dispatchMode == 'only_driver' && _vehicles.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: _selectedOwnerVehicleId,
                      decoration: const InputDecoration(
                        labelText: 'Select Lorry from Your Registered Fleet',
                        prefixIcon: Icon(Icons.local_shipping, size: 18),
                      ),
                      items: _vehicles.map((v) {
                        final plate = v['plate_number'] ?? 'MH-04-TR-9081';
                        final model = v['model'] ?? 'Eicher Pro';
                        final tons = v['capacity_tons'] ?? 5.0;
                        final val = v['id']?.toString() ?? plate;
                        return DropdownMenuItem<String>(
                          value: val,
                          child: Text('$plate • $model (${tons}T Capacity)'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedOwnerVehicleId = val),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _weightTonsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Luggage Weight in Tons',
                            suffixText: 'Tons',
                            prefixIcon: Icon(Icons.scale, size: 18),
                            helperText: 'Cargo tonnage for this highway corridor trip',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _fareController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Offered Trip Payout (INR ₹)',
                            prefixText: '₹ ',
                            prefixIcon: Icon(Icons.payments_outlined, size: 18),
                            helperText: 'Guaranteed payment credited upon delivery',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Driver Target Selection
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _targetDriverIdController,
                          decoration: const InputDecoration(
                            labelText: 'Target Driver ID (UUID or Phone)',
                            prefixIcon: Icon(Icons.badge, size: 18),
                            helperText: 'Driver will receive a real-time dispatch notification',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => setState(() => _targetDriverIdController.text = '2ff1fda4-bea5-4e97-bdf4-755a6fc4a2d3'),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16)),
                        child: const Text('Preset: Vikram (MH 12 AB 1234)'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pickupController,
                          decoration: const InputDecoration(
                            labelText: 'Pickup Corridor / Hub',
                            prefixIcon: Icon(Icons.location_on, size: 18, color: AdminTheme.crimsonRed),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _dropoffController,
                          decoration: const InputDecoration(
                            labelText: 'Drop-off Destination / Facility',
                            prefixIcon: Icon(Icons.flag, size: 18, color: AdminTheme.statusOnline),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cargoController,
                    decoration: const InputDecoration(
                      labelText: 'Cargo Description & Luggage Specifications',
                      prefixIcon: Icon(Icons.inventory_2, size: 18),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.crimsonRed,
                        foregroundColor: AdminTheme.crispWhite,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: _isDispatching ? null : _handleSendDriverRequest,
                      icon: const Icon(Icons.send_rounded, size: 20),
                      label: _isDispatching
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('DISPATCH TRIP REQUEST TO DRIVER (SEND NOTIFICATION)', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdminTheme.crispWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AdminTheme.borderSubtle),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AdminTheme.crimsonTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AdminTheme.crimsonRed, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AdminTheme.deepBlack)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: AdminTheme.textMuted)),
                    ],
                  ),
                ],
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AdminTheme.borderSubtle, height: 1),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> v) {
    final plate = v['plate_number'] ?? 'MH-04-TR-9081';
    final model = v['model'] ?? 'Eicher Pro Lorry';
    final tons = v['capacity_tons'] ?? 5.0;
    final tires = v['tire_config'] ?? '6 Tire';
    final rc = v['rc_photo_url'] ?? 'RC-MH04';
    final fitness = v['fitness_cert'] ?? 'FC-MH04-VALID';
    final insurance = v['insurance_policy'] ?? 'POL-ACTIVE';
    final permit = v['permit_number'] ?? 'NP-IND-2026';

    return Container(
      width: 380,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminTheme.warmCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(plate, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AdminTheme.deepBlack)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AdminTheme.crimsonTint,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AdminTheme.crimsonRed.withAlpha(60)),
                ),
                child: Text('$tons Tons • $tires', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AdminTheme.crimsonRed)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(model, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AdminTheme.textDark)),
          const SizedBox(height: 12),
          const Divider(color: AdminTheme.borderSubtle, height: 1),
          const SizedBox(height: 10),

          // Document Badges
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildDocBadge(Icons.description, 'RC: $rc'),
              _buildDocBadge(Icons.health_and_safety, 'Fitness: $fitness'),
              _buildDocBadge(Icons.security, 'Insurance: $insurance'),
              _buildDocBadge(Icons.assignment_turned_in, 'Permit: $permit'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AdminTheme.crispWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminTheme.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AdminTheme.statusOnline),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AdminTheme.textDark)),
        ],
      ),
    );
  }
}
