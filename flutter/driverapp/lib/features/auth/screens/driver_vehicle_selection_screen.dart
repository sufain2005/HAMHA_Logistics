import 'package:flutter/material.dart';
import '../../../core/theme/driver_theme.dart';
import '../../../core/services/driver_api_service.dart';
import 'driver_document_upload_screen.dart';

class DriverVehicleSelectionScreen extends StatefulWidget {
  const DriverVehicleSelectionScreen({super.key});

  @override
  State<DriverVehicleSelectionScreen> createState() => _DriverVehicleSelectionScreenState();
}

class _DriverVehicleSelectionScreenState extends State<DriverVehicleSelectionScreen> {
  String _selectedCategory = 'van';
  final _plateController = TextEditingController(text: 'MH 12 AB 1234');
  final _modelController = TextEditingController(text: 'Tata Ace Gold 1.5T');

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _plateController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveVehicle() async {
    final plate = _plateController.text.trim();
    final model = _modelController.text.trim();

    if (plate.isEmpty || model.isEmpty) {
      setState(() => _errorMessage = 'Please provide plate number and vehicle model');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await DriverApiService().submitVehicleDetails(
        vehicleType: _selectedCategory,
        plateNumber: plate,
        model: model,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DriverDocumentUploadScreen(),
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DriverTheme.warmCream,
      appBar: AppBar(
        title: const Text('Vehicle Registration'),
        backgroundColor: DriverTheme.crispWhite,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step Progress Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: DriverTheme.crispWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: DriverTheme.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'STEP 2 OF 3: FLEET ASSET ASSIGNMENT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: DriverTheme.crimsonRed,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: DriverTheme.warmCream,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('66%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Select Vehicle Category',
                  style: TextStyle(
                    color: DriverTheme.deepBlack,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose the logistics vehicle you operate to receive tailored cargo offers.',
                  style: TextStyle(color: DriverTheme.textMuted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DriverTheme.crimsonTint,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DriverTheme.crimsonRed.withAlpha(80)),
                    ),
                    child: Text(_errorMessage!, style: const TextStyle(color: DriverTheme.crimsonRed, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3 Vehicle Cards
                _buildVehicleOption(
                  id: 'bike',
                  title: 'Two-Wheeler (Express Courier)',
                  specs: 'Up to 25 kg • 40 L Bag • City Document & Parcel Express',
                  icon: Icons.two_wheeler,
                ),
                const SizedBox(height: 12),
                _buildVehicleOption(
                  id: 'van',
                  title: 'Delivery Van / Light Truck (1.5T)',
                  specs: 'Up to 1,200 kg • 180 cu ft • Mid-mile Retail & Heavy Boxes',
                  icon: Icons.airport_shuttle,
                ),
                const SizedBox(height: 12),
                _buildVehicleOption(
                  id: 'truck',
                  title: 'Heavy Logistics Truck (16T+)',
                  specs: 'Up to 15,000 kg • Full Container • Interstate Freight Haulage',
                  icon: Icons.local_shipping,
                ),
                const SizedBox(height: 24),

                // Vehicle Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: DriverTheme.crispWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: DriverTheme.borderSubtle),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'REGISTRATION PLATE NUMBER',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: DriverTheme.textMuted),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _plateController,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: DriverTheme.deepBlack),
                        decoration: const InputDecoration(
                          hintText: 'e.g. MH 12 AB 1234',
                          prefixIcon: Icon(Icons.pin, color: DriverTheme.crimsonRed),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'VEHICLE MAKE & MODEL',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: DriverTheme.textMuted),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _modelController,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: DriverTheme.deepBlack),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Tata Ace Gold / Ashok Leyland Dost',
                          prefixIcon: Icon(Icons.directions_car, color: DriverTheme.textDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Action Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSaveVehicle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DriverTheme.crimsonRed,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: DriverTheme.crispWhite, strokeWidth: 2.5),
                        )
                      : const Text('CONTINUE TO DOCUMENT UPLOAD'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleOption({
    required String id,
    required String title,
    required String specs,
    required IconData icon,
  }) {
    final isSelected = _selectedCategory == id;

    return InkWell(
      onTap: () => setState(() => _selectedCategory = id),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? DriverTheme.crimsonTint : DriverTheme.crispWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? DriverTheme.crimsonRed : DriverTheme.borderSubtle,
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? DriverTheme.crimsonRed : DriverTheme.deepBlack,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: DriverTheme.crispWhite, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? DriverTheme.crimsonDark : DriverTheme.deepBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    specs,
                    style: const TextStyle(fontSize: 12, color: DriverTheme.textMuted, height: 1.3),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? DriverTheme.crimsonRed : DriverTheme.borderSubtle,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
