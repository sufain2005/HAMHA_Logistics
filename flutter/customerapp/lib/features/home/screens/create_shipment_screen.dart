import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/quote_model.dart';
import '../../../core/network/api_client.dart';
import '../widgets/cost_calculator_widget.dart';
import '../../tracking/screens/order_tracking_screen.dart';

class CreateShipmentScreen extends StatefulWidget {
  const CreateShipmentScreen({super.key});

  @override
  State<CreateShipmentScreen> createState() => _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends State<CreateShipmentScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedCargo = 'Industrial Equipment';
  final _weightController = TextEditingController(text: '18.5');
  final _descriptionController = TextEditingController(text: 'Heavy duty boxed components');

  // Pickup details (Default San Francisco coordinates for demo)
  final _pickupAddressController = TextEditingController(text: '750 Brannan St, San Francisco, CA');
  final double _pickupLon = -122.4022;
  final double _pickupLat = 37.7758;

  // Dropoff details
  final _dropoffAddressController = TextEditingController(text: '201 3rd St, San Francisco, CA');
  final double _dropoffLon = -122.4005;
  final double _dropoffLat = 37.7858;

  final _contactNameController = TextEditingController(text: 'Receiving Dock Manager');
  final _contactPhoneController = TextEditingController(text: '+14155552671');

  QuoteModel? _currentQuote;
  bool _isCalculating = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateQuote();
    });
  }

  Future<void> _calculateQuote() async {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) return;

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

  Future<void> _handleProceed() async {
    if (!_formKey.currentState!.validate()) return;

    final weight = double.tryParse(_weightController.text.trim()) ?? 10.0;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiClient().createOrder(
        cargoType: _selectedCargo,
        weightKg: weight,
        packageDescription: _descriptionController.text.trim(),
        pickupAddress: _pickupAddressController.text.trim(),
        pickupLon: _pickupLon,
        pickupLat: _pickupLat,
        dropoffAddress: _dropoffAddressController.text.trim(),
        dropoffLon: _dropoffLon,
        dropoffLat: _dropoffLat,
        dropoffContactName: _contactNameController.text.trim(),
        dropoffContactPhone: _contactPhoneController.text.trim(),
      );

      if (!mounted) return;

      final newOrderId = res['order']['id'];

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: HamhaTheme.statusDelivered,
          content: Text('Shipment booked successfully! Driver dispatch initiated.'),
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
        title: const Text('Create New Shipment'),
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
            constraints: const BoxConstraints(maxWidth: 680),
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
                      child: Text(_errorMessage!, style: const TextStyle(color: HamhaTheme.crimsonDark, fontSize: 13)),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // SECTION 1: Cargo Specifications
                  _buildSectionCard(
                    title: '1. Package & Cargo Details',
                    icon: Icons.inventory_2_outlined,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedCargo,
                        decoration: const InputDecoration(labelText: 'Cargo Category'),
                        items: const [
                          DropdownMenuItem(value: 'Industrial Equipment', child: Text('Industrial Equipment')),
                          DropdownMenuItem(value: 'Medical Supplies', child: Text('Medical Supplies (Fragile)')),
                          DropdownMenuItem(value: 'Electronics & Hardware', child: Text('Electronics & Hardware')),
                          DropdownMenuItem(value: 'General Commercial Freight', child: Text('General Commercial Freight')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCargo = val);
                            _calculateQuote();
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Total Weight (kg)',
                          suffixText: 'KG',
                        ),
                        validator: (val) => val == null || double.tryParse(val) == null ? 'Enter valid weight' : null,
                        onChanged: (_) => _calculateQuote(),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Package Description / Notes for Driver',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SECTION 2: Pickup Point
                  _buildSectionCard(
                    title: '2. Origin (Pick-up Point)',
                    icon: Icons.trip_origin,
                    iconColor: HamhaTheme.crimsonRed,
                    children: [
                      TextFormField(
                        controller: _pickupAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Pick-up Street Address',
                          prefixIcon: Icon(Icons.location_on, color: HamhaTheme.crimsonRed),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Address required' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SECTION 3: Drop-off Point
                  _buildSectionCard(
                    title: '3. Destination (Drop-off Point)',
                    icon: Icons.flag_outlined,
                    iconColor: HamhaTheme.deepBlack,
                    children: [
                      TextFormField(
                        controller: _dropoffAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Destination Street Address',
                          prefixIcon: Icon(Icons.pin_drop, color: HamhaTheme.deepBlack),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Address required' : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _contactNameController,
                              decoration: const InputDecoration(labelText: 'Receiver Name'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _contactPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(labelText: 'Receiver Phone'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // SECTION 4: Cost Calculator Component
                  CostCalculatorWidget(
                    quote: _currentQuote,
                    isLoading: _isCalculating,
                    onCalculate: _calculateQuote,
                    onProceed: _isSubmitting ? null : _handleProceed,
                  ),
                  const SizedBox(height: 30),
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
    Color iconColor = HamhaTheme.deepBlack,
    required List<Widget> children,
  }) {
    return Card(
      color: HamhaTheme.crispWhite,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: HamhaTheme.borderSubtle, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: HamhaTheme.deepBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
