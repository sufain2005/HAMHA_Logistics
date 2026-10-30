import 'package:flutter/material.dart';
import '../../../core/theme/admin_theme.dart';
import '../../../core/network/admin_api_client.dart';

class TariffsPricingScreen extends StatefulWidget {
  const TariffsPricingScreen({super.key});

  @override
  State<TariffsPricingScreen> createState() => _TariffsPricingScreenState();
}

class _TariffsPricingScreenState extends State<TariffsPricingScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Active Tariffs State
  double _baseFee = 350.0;
  double _perKmRate = 25.0;
  double _weightBaseAllowanceKg = 10.0;
  double _perKgRate = 18.0;
  double _heavyWeightPerKgRate = 12.0;
  double _minimumFare = 250.0;
  double _gstPercent = 18.0;

  Map<String, double> _vehicleRates = {
    'bike': 12.0,
    'mini_van': 22.0,
    'van': 32.0,
    'truck': 55.0,
    'heavy_4tire': 45.0,
    'heavy_6tire': 65.0,
    'heavy_8tire': 85.0,
    'heavy_12tire': 110.0,
  };

  String _lastUpdated = 'Just Now';

  // Live Customer Simulator State
  double _simDistanceKm = 85.0;
  double _simWeightKg = 25.0;
  String _simVehicle = 'van';

  @override
  void initState() {
    super.initState();
    _loadTariffs();
  }

  Future<void> _loadTariffs() async {
    setState(() => _isLoading = true);
    final tariffs = await AdminApiClient().fetchTariffs();
    if (mounted) {
      setState(() {
        _baseFee = (tariffs['baseFee'] as num?)?.toDouble() ?? 350.0;
        _perKmRate = (tariffs['perKmRate'] as num?)?.toDouble() ?? 25.0;
        _weightBaseAllowanceKg = (tariffs['weightBaseAllowanceKg'] as num?)?.toDouble() ?? 10.0;
        _perKgRate = (tariffs['perKgRate'] as num?)?.toDouble() ?? 18.0;
        _heavyWeightPerKgRate = (tariffs['heavyWeightPerKgRate'] as num?)?.toDouble() ?? 12.0;
        _minimumFare = (tariffs['minimumFare'] as num?)?.toDouble() ?? 250.0;
        _gstPercent = (tariffs['gstPercent'] as num?)?.toDouble() ?? 18.0;

        if (tariffs['vehicleRates'] is Map) {
          final vr = tariffs['vehicleRates'] as Map;
          vr.forEach((k, v) {
            if (v is num) _vehicleRates[k.toString()] = v.toDouble();
          });
        }

        _lastUpdated = tariffs['updatedAt'] != null
            ? DateTime.tryParse(tariffs['updatedAt'].toString())?.toLocal().toString().split('.').first ?? 'Today'
            : 'Today';

        _isLoading = false;
      });
    }
  }

  Future<void> _saveTariffs() async {
    setState(() => _isSaving = true);

    await AdminApiClient().updateTariffs({
      'baseFee': _baseFee,
      'perKmRate': _perKmRate,
      'vehicleRates': _vehicleRates,
      'weightBaseAllowanceKg': _weightBaseAllowanceKg,
      'perKgRate': _perKgRate,
      'heavyWeightPerKgRate': _heavyWeightPerKgRate,
      'minimumFare': _minimumFare,
      'gstPercent': _gstPercent,
    });

    if (mounted) {
      setState(() {
        _isSaving = false;
        _lastUpdated = DateTime.now().toLocal().toString().split('.').first;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AdminTheme.statusOnline,
          content: Text('✓ Freight Tariffs saved & published! Customer App quotes now strictly follow these rates.'),
        ),
      );
    }
  }

  double _calculateSimFare() {
    final kmRate = _vehicleRates[_simVehicle] ?? _perKmRate;
    final distFee = _simDistanceKm * kmRate;
    final excessWeight = _simWeightKg > _weightBaseAllowanceKg ? (_simWeightKg - _weightBaseAllowanceKg) : 0.0;
    final weightFee = excessWeight * _perKgRate;
    final subtotal = _baseFee + distFee + weightFee;
    final total = subtotal + (subtotal * (_gstPercent / 100.0));
    return total < _minimumFare ? _minimumFare : total;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AdminTheme.crimsonRed));
    }

    final simTotal = _calculateSimFare();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Freight Tariffs & Pricing Engine',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AdminTheme.deepBlack),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure Distance Cost (₹/KM), Weight Cost (₹/KG), and Vehicle Tier Rates for all Customers.',
                    style: const TextStyle(fontSize: 12, color: AdminTheme.textMuted),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AdminTheme.canvasBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AdminTheme.borderSubtle),
                    ),
                    child: Text(
                      'Last Published: $_lastUpdated',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AdminTheme.textMuted),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveTariffs,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.crimsonRed,
                      foregroundColor: AdminTheme.crispWhite,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: _isSaving
                        ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.cloud_upload_outlined, size: 16),
                    label: const Text('SAVE & PUBLISH TARIFFS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Core KPI Cards
          Row(
            children: [
              Expanded(child: _buildTariffCard('BASE CONSIGNMENT FARE', '₹${_baseFee.toInt()}', 'Flag drop handling fee', Icons.flag_outlined, () => _editNumber('Base Consignment Fee', _baseFee, (val) => setState(() => _baseFee = val)))),
              const SizedBox(width: 14),
              Expanded(child: _buildTariffCard('DEFAULT PRICE PER KM', '₹${_perKmRate.toInt()} / km', 'Standard highway freight', Icons.add_road, () => _editNumber('Default Per KM Rate', _perKmRate, (val) => setState(() => _perKmRate = val)))),
              const SizedBox(width: 14),
              Expanded(child: _buildTariffCard('WEIGHT PRICE PER KG', '₹${_perKgRate.toInt()} / kg', 'Above ${_weightBaseAllowanceKg.toInt()}kg free allowance', Icons.scale_outlined, () => _editNumber('Weight Price per KG', _perKgRate, (val) => setState(() => _perKgRate = val)))),
              const SizedBox(width: 14),
              Expanded(child: _buildTariffCard('MINIMUM BOOKING FARE', '₹${_minimumFare.toInt()}', 'Guaranteed carrier floor', Icons.security, () => _editNumber('Minimum Fare', _minimumFare, (val) => setState(() => _minimumFare = val)))),
            ],
          ),
          const SizedBox(height: 24),

          // Split View: Vehicle Rates on Left, Live Customer Simulator on Right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT: Vehicle-Specific Per-KM Pricing Matrix
              Expanded(
                flex: 7,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AdminTheme.crispWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AdminTheme.borderSubtle, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_shipping_outlined, color: AdminTheme.crimsonRed, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'COMMERCIAL FLEET DISTANCE RATES (₹ PER KM)',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AdminTheme.deepBlack, letterSpacing: 0.6),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Customers selecting these vehicles will be charged strictly according to these rates per kilometer.',
                        style: TextStyle(fontSize: 11, color: AdminTheme.textMuted),
                      ),
                      const SizedBox(height: 16),

                      _buildVehicleRateRow('bike', 'Two-Wheeler / Bike Express', 'Small envelopes, parcels up to 20kg', Icons.two_wheeler),
                      _buildVehicleRateRow('mini_van', 'Mini Van (Tata Ace / Dost)', 'Intra-city payloads up to 1,000kg (1 Ton)', Icons.airport_shuttle),
                      _buildVehicleRateRow('van', 'Van (Bolero Maxi / 407)', 'Medium freight payloads up to 2,500kg', Icons.directions_bus),
                      _buildVehicleRateRow('truck', 'Commercial Truck (Eicher Pro / 4T)', 'Heavy freight payloads up to 4,500kg', Icons.local_shipping),
                      _buildVehicleRateRow('heavy_4tire', '4-Tire Commercial Multi-Axle', 'Medium industrial cargo', Icons.tire_repair),
                      _buildVehicleRateRow('heavy_6tire', '6-Tire Heavy Cargo Multi-Axle', 'Bulk industrial machinery & metals', Icons.fire_truck),
                      _buildVehicleRateRow('heavy_8tire', '8-Tire Heavy Transport Multi-Axle', 'Heavy long-haul container carrier', Icons.fire_truck),
                      _buildVehicleRateRow('heavy_12tire', '12-Tire Multi-Axle Giant', 'Oversized heavy equipment & bulk freight', Icons.fire_truck),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // RIGHT: Live Customer Quote Simulator
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AdminTheme.canvasBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AdminTheme.borderSubtle, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.preview_outlined, color: AdminTheme.crimsonRed, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'LIVE CUSTOMER QUOTE PREVIEW',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AdminTheme.deepBlack, letterSpacing: 0.6),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AdminTheme.statusOnline.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('REAL-TIME', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AdminTheme.statusOnline)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Simulate what customers will see when booking on their app with these rates:',
                        style: TextStyle(fontSize: 11, color: AdminTheme.textMuted),
                      ),
                      const SizedBox(height: 16),

                      // Simulator Vehicle Selector
                      const Text('TEST VEHICLE:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminTheme.textMuted)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _simVehicle,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AdminTheme.crispWhite,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                        items: _vehicleRates.keys.map((k) {
                          return DropdownMenuItem(value: k, child: Text('${k.replaceAll("_", " ").toUpperCase()} (₹${_vehicleRates[k]?.toInt()}/km)'));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _simVehicle = val);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Simulator Distance Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('DISTANCE (KM):', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminTheme.textMuted)),
                          Text('${_simDistanceKm.toInt()} KM', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AdminTheme.deepBlack)),
                        ],
                      ),
                      Slider(
                        value: _simDistanceKm,
                        min: 5,
                        max: 1000,
                        divisions: 199,
                        activeColor: AdminTheme.crimsonRed,
                        onChanged: (val) => setState(() => _simDistanceKm = val),
                      ),

                      // Simulator Weight Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('WEIGHT (KG):', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminTheme.textMuted)),
                          Text('${_simWeightKg.toInt()} KG', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AdminTheme.deepBlack)),
                        ],
                      ),
                      Slider(
                        value: _simWeightKg,
                        min: 1,
                        max: 200,
                        divisions: 199,
                        activeColor: AdminTheme.deepBlack,
                        onChanged: (val) => setState(() => _simWeightKg = val),
                      ),

                      const Divider(color: AdminTheme.borderSubtle, height: 20),

                      // Breakdown
                      _buildSimRow('Base Consignment Fee:', '₹${_baseFee.toInt()}'),
                      _buildSimRow('Distance Fare (${_simDistanceKm.toInt()} km @ ₹${(_vehicleRates[_simVehicle] ?? _perKmRate).toInt()}/km):', '₹${(_simDistanceKm * (_vehicleRates[_simVehicle] ?? _perKmRate)).toInt()}'),
                      _buildSimRow('Weight Surcharge (${(_simWeightKg > _weightBaseAllowanceKg ? _simWeightKg - _weightBaseAllowanceKg : 0).toInt()}kg excess):', '₹${((_simWeightKg > _weightBaseAllowanceKg ? _simWeightKg - _weightBaseAllowanceKg : 0) * _perKgRate).toInt()}'),
                      _buildSimRow('GST (18% Statutory Freight):', '₹${((_calculateSimFare() / 1.18) * 0.18).toInt()}'),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AdminTheme.crispWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AdminTheme.crimsonRed.withAlpha(60)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Customer Sees Total:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AdminTheme.deepBlack)),
                            Text('₹${simTotal.round()} INR', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AdminTheme.crimsonRed)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTariffCard(String title, String value, String subtitle, IconData icon, VoidCallback onEdit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.crispWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminTheme.borderSubtle, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: AdminTheme.crimsonRed),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AdminTheme.canvasBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('EDIT', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: AdminTheme.crimsonRed)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AdminTheme.deepBlack)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminTheme.textMuted, letterSpacing: 0.5)),
          Text(subtitle, style: const TextStyle(fontSize: 9.5, color: AdminTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildVehicleRateRow(String key, String title, String subtitle, IconData icon) {
    final rate = _vehicleRates[key] ?? 25.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AdminTheme.canvasBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AdminTheme.deepBlack),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AdminTheme.deepBlack)),
                Text(subtitle, style: const TextStyle(fontSize: 9.5, color: AdminTheme.textMuted)),
              ],
            ),
          ),
          // Price controls (- / +)
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 18, color: AdminTheme.textMuted),
                onPressed: () {
                  if (rate > 5) setState(() => _vehicleRates[key] = rate - 1.0);
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AdminTheme.crispWhite,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AdminTheme.borderSubtle),
                ),
                child: Text('₹${rate.toInt()} / km', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AdminTheme.crimsonRed)),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 18, color: AdminTheme.textMuted),
                onPressed: () {
                  setState(() => _vehicleRates[key] = rate + 1.0);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AdminTheme.textMuted)),
          Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AdminTheme.deepBlack)),
        ],
      ),
    );
  }

  void _editNumber(String title, double current, ValueChanged<double> onSaved) {
    final controller = TextEditingController(text: current.toInt().toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $title', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'New Value (INR ₹)',
            prefixText: '₹ ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.crimsonRed),
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null) {
                onSaved(val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('UPDATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

