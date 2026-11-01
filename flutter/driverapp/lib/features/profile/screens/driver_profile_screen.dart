import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/driver_user_model.dart';
import '../../../core/theme/driver_theme.dart';
import '../../../core/services/driver_api_service.dart';
import '../../../core/services/driver_socket_service.dart';
import '../../auth/screens/driver_welcome_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  bool _voiceGuidance = true;
  bool _soundAlerts = true;
  bool _fastagExpressways = true;
  bool _dailyPayouts = true;

  Map<String, dynamic>? _fleetOwner;
  bool _isLoadingOwner = true;

  // Vehicle Specifications State
  late String _vehicleType;
  late String _plateNumber;
  late String _vehicleModel;
  String _payloadCapacity = '1,200 kg • 180 cu ft';
  String _fastagId = 'FAST-8839210-ICICI';
  String _pucValidity = 'Valid till 15 Dec 2027';

  // Bank & UPI Settlement State
  String _upiId = '9823411209@okhdfcbank';
  String _bankName = 'HDFC Bank';
  String _accountNumber = '•••• 4892';
  String _fullAccountNumber = '50100489211234';
  String _ifscCode = 'HDFC0001242';
  String _accountHolder = 'Vikram S.';

  @override
  void initState() {
    super.initState();
    final driver = DriverApiService().currentDriver;
    _vehicleType = driver?.vehicleType ?? 'Truck';
    _plateNumber = driver?.plateNumber ?? 'MH 12 AB 1234';
    _vehicleModel = driver?.vehicleModel ?? 'Tata Ace Gold 1.5T';
    _loadFleetOwner();
  }

  Future<void> _loadFleetOwner() async {
    final owner = await DriverApiService().fetchFleetOwnerContact();
    if (mounted) {
      setState(() {
        _fleetOwner = owner;
        _isLoadingOwner = false;
      });
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DriverTheme.crispWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out of Carrier Account?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to end your shift and disconnect from HAMHA Logistics?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: DriverTheme.textMuted, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DriverTheme.crimsonRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              DriverSocketService().toggleOnline(false);
              DriverSocketService().disconnect();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const DriverWelcomeScreen()),
                (route) => false,
              );
            },
            child: const Text('SIGN OUT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditVehicleModal() {
    String selectedClass = _vehicleType;
    final plateCtrl = TextEditingController(text: _plateNumber);
    final modelCtrl = TextEditingController(text: _vehicleModel);
    final capacityCtrl = TextEditingController(text: _payloadCapacity);
    final fastagCtrl = TextEditingController(text: _fastagId);
    final pucCtrl = TextEditingController(text: _pucValidity);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: DriverTheme.crispWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: DriverTheme.borderSubtle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Icon(Icons.local_shipping, color: DriverTheme.crimsonRed, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Update Vehicle & Asset Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: DriverTheme.deepBlack),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Update your commercial fleet vehicle specifications visible to Fleet Owners.',
                    style: TextStyle(fontSize: 12, color: DriverTheme.textMuted),
                  ),
                  const SizedBox(height: 18),

                  DropdownButtonFormField<String>(
                    value: ['Truck', 'Box Truck', 'Van', 'Pickup', 'Trailer', 'Bike'].contains(selectedClass)
                        ? selectedClass
                        : 'Truck',
                    decoration: const InputDecoration(labelText: 'Vehicle Fleet Class'),
                    items: const [
                      DropdownMenuItem(value: 'Truck', child: Text('Standard Truck (Heavy Commercial)')),
                      DropdownMenuItem(value: 'Box Truck', child: Text('10-Ton Box Truck (Closed Body)')),
                      DropdownMenuItem(value: 'Van', child: Text('Cargo Van / Tempo (LCV)')),
                      DropdownMenuItem(value: 'Pickup', child: Text('Pickup Truck / Open Body')),
                      DropdownMenuItem(value: 'Trailer', child: Text('Heavy Prime Mover / Trailer')),
                      DropdownMenuItem(value: 'Bike', child: Text('Motorcycle / 2-Wheeler (Express Parcel)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedClass = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: plateCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Registration Plate Number',
                      hintText: 'e.g. MH 12 AB 1234',
                      prefixIcon: Icon(Icons.badge, color: DriverTheme.textDark),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter plate number' : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: modelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Make & Model',
                      hintText: 'e.g. Tata Ace Gold 1.5T / Ashok Leyland 1616',
                      prefixIcon: Icon(Icons.directions_car, color: DriverTheme.textDark),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: capacityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Payload Capacity & Volume',
                      hintText: 'e.g. 1,200 kg • 180 cu ft or 10.0 Tons',
                      prefixIcon: Icon(Icons.scale, color: DriverTheme.textDark),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: fastagCtrl,
                    decoration: const InputDecoration(
                      labelText: 'FASTag Toll Account / Tag ID',
                      hintText: 'e.g. FAST-8839210-ICICI',
                      prefixIcon: Icon(Icons.toll, color: DriverTheme.textDark),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      setState(() {
                        _vehicleType = selectedClass;
                        _plateNumber = plateCtrl.text.trim().toUpperCase();
                        _vehicleModel = modelCtrl.text.trim().isNotEmpty ? modelCtrl.text.trim() : 'Commercial Asset';
                        _payloadCapacity = capacityCtrl.text.trim().isNotEmpty ? capacityCtrl.text.trim() : 'Standard Payload';
                        _fastagId = fastagCtrl.text.trim().isNotEmpty ? fastagCtrl.text.trim() : 'FAST-ACTIVE';
                        _pucValidity = pucCtrl.text.trim().isNotEmpty ? pucCtrl.text.trim() : 'Valid';
                      });

                      // Update DriverApiService currentDriver model
                      final current = DriverApiService().currentDriver;
                      if (current != null) {
                        DriverApiService().currentDriver = DriverUserModel(
                          id: current.id,
                          name: current.name,
                          phone: current.phone,
                          email: current.email,
                          vehicleType: _vehicleType,
                          plateNumber: _plateNumber,
                          vehicleModel: _vehicleModel,
                          isVerified: current.isVerified,
                          isOnline: current.isOnline,
                          isOnboarded: current.isOnboarded,
                          rating: current.rating,
                          todayEarnings: current.todayEarnings,
                          todayTrips: current.todayTrips,
                          onlineHours: current.onlineHours,
                        );
                      }

                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vehicle specifications updated successfully!'),
                          backgroundColor: DriverTheme.statusOnline,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DriverTheme.crimsonRed,
                      foregroundColor: DriverTheme.crispWhite,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('SAVE VEHICLE SPECIFICATIONS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditBankModal() {
    final holderCtrl = TextEditingController(text: _accountHolder);
    final upiCtrl = TextEditingController(text: _upiId);
    final bankCtrl = TextEditingController(text: _bankName);
    final accountCtrl = TextEditingController(text: _fullAccountNumber);
    final ifscCtrl = TextEditingController(text: _ifscCode);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: DriverTheme.crispWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: DriverTheme.borderSubtle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Icon(Icons.account_balance, color: DriverTheme.crimsonRed, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Edit Bank & UPI Payout Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: DriverTheme.deepBlack),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Fleet Owners will use these exact details to transfer your corridor freight payments.',
                    style: TextStyle(fontSize: 12, color: DriverTheme.textMuted),
                  ),
                  const SizedBox(height: 18),

                  TextFormField(
                    controller: holderCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Account Holder Name',
                      hintText: 'e.g. Vikram Sharma',
                      prefixIcon: Icon(Icons.person_outline, color: DriverTheme.textDark),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter account holder name' : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: upiCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Primary UPI ID / VPA',
                      hintText: 'e.g. 9823411209@okhdfcbank or driver@upi',
                      prefixIcon: Icon(Icons.qr_code_2, color: DriverTheme.crimsonRed),
                    ),
                    validator: (val) => (val == null || !val.contains('@')) ? 'Please enter a valid UPI ID (e.g. user@bank)' : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: bankCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Bank Name',
                      hintText: 'e.g. HDFC Bank, SBI, ICICI Bank',
                      prefixIcon: Icon(Icons.account_balance, color: DriverTheme.textDark),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter bank name' : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: accountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Full Bank Account Number',
                      hintText: 'e.g. 50100489211234',
                      prefixIcon: Icon(Icons.credit_card, color: DriverTheme.textDark),
                    ),
                    validator: (val) => (val == null || val.trim().length < 8) ? 'Enter valid account number (min 8 digits)' : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: ifscCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Bank IFSC Code',
                      hintText: 'e.g. HDFC0001242',
                      prefixIcon: Icon(Icons.pin, color: DriverTheme.textDark),
                    ),
                    validator: (val) => (val == null || val.trim().length < 5) ? 'Enter valid IFSC code' : null,
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final rawAcc = accountCtrl.text.trim();
                      final masked = rawAcc.length >= 4 ? '•••• ${rawAcc.substring(rawAcc.length - 4)}' : rawAcc;
                      setState(() {
                        _accountHolder = holderCtrl.text.trim();
                        _upiId = upiCtrl.text.trim();
                        _bankName = bankCtrl.text.trim();
                        _fullAccountNumber = rawAcc;
                        _accountNumber = masked;
                        _ifscCode = ifscCtrl.text.trim().toUpperCase();
                      });

                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bank & UPI payout settings saved!'),
                          backgroundColor: DriverTheme.statusOnline,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DriverTheme.crimsonRed,
                      foregroundColor: DriverTheme.crispWhite,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('SAVE BANK & UPI DETAILS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDocumentViewer(String title, String docNumber, String status) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: DriverTheme.crispWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: DriverTheme.borderSubtle, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DriverTheme.statusOnline.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DriverTheme.statusOnline),
                  ),
                  child: Text(status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: DriverTheme.statusOnline)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Credential Number: $docNumber', style: const TextStyle(fontWeight: FontWeight.w700, color: DriverTheme.textDark)),
            const SizedBox(height: 6),
            const Text('Audited & verified by HAMHA Fleet Compliance Bureau under Central Motor Vehicles Act.', style: TextStyle(fontSize: 12, color: DriverTheme.textMuted)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: DriverTheme.deepBlack,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driver = DriverApiService().currentDriver;

    return Scaffold(
      backgroundColor: DriverTheme.warmCream,
      appBar: AppBar(
        backgroundColor: DriverTheme.crispWhite,
        title: const Text('Driver Profile & Fleet Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: DriverTheme.crimsonRed),
            onPressed: _handleLogout,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. DRIVER HERO CARD
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: DriverTheme.crispWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: DriverTheme.borderSubtle, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: DriverTheme.deepBlack,
                            child: const Icon(Icons.person, color: DriverTheme.crispWhite, size: 40),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: DriverTheme.statusOnline,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified, color: DriverTheme.crispWhite, size: 14),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  driver?.name ?? 'Rajesh Kumar',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: DriverTheme.deepBlack,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            InkWell(
                              onTap: () {
                                final dId = driver?.customDriverId ?? '202698200001V';
                                Clipboard.setData(ClipboardData(text: dId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Driver ID copied to clipboard: $dId'),
                                    backgroundColor: DriverTheme.statusOnline,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Row(
                                children: [
                                  Text(
                                    'DRIVER ID: ${driver?.customDriverId ?? "202698200001V"}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: DriverTheme.crimsonRed,
                                      letterSpacing: 0.5,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.copy, size: 12, color: DriverTheme.textMuted),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: DriverTheme.warmCream,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: DriverTheme.borderSubtle),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 13),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${driver?.rating ?? 4.92}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                                      ),
                                      const Text(
                                        ' (428 reviews)',
                                        style: TextStyle(fontSize: 10, color: DriverTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: DriverTheme.crimsonTint,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: DriverTheme.crimsonRed.withAlpha(60)),
                                  ),
                                  child: const Text(
                                    'ELITE PILOT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: DriverTheme.crimsonRed,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: DriverTheme.borderSubtle, height: 1),
                  const SizedBox(height: 16),

                  // Lifetime stats (Fresh Driver Profile)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLifetimeStat('LIFETIME EARNINGS', '₹0'),
                      Container(width: 1, height: 30, color: DriverTheme.borderSubtle),
                      _buildLifetimeStat('TOTAL DELIVERIES', '0 Trips'),
                      Container(width: 1, height: 30, color: DriverTheme.borderSubtle),
                      _buildLifetimeStat('SAFETY SCORE', '100/100'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. ASSIGNED FLEET OWNER & DEPOT HQ
            _buildSectionHeader('Assigned Fleet Owner & Depot HQ', Icons.business_outlined),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: DriverTheme.crispWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DriverTheme.borderSubtle, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _isLoadingOwner
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(color: DriverTheme.crimsonRed),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: DriverTheme.crimsonTint,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.shield, color: DriverTheme.crimsonRed, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _fleetOwner?['name'] ?? 'Rajesh Singhania',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: DriverTheme.deepBlack,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _fleetOwner?['companyName'] ?? 'HAMHA Logistics Pvt Ltd',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: DriverTheme.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: DriverTheme.statusOnline.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: DriverTheme.statusOnline),
                              ),
                              child: const Text(
                                'ACTIVE HQ',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: DriverTheme.statusOnline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: DriverTheme.borderSubtle, height: 1),
                        const SizedBox(height: 14),

                        // Owner Primary Mobile Number
                        Row(
                          children: [
                            const Icon(Icons.phone, color: DriverTheme.crimsonRed, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'OWNER PRIMARY MOBILE',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: DriverTheme.textMuted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _fleetOwner?['phone'] ?? '+91 98200 11223',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: DriverTheme.deepBlack,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18, color: DriverTheme.textMuted),
                              tooltip: 'Copy Primary Phone',
                              onPressed: () {
                                final p = _fleetOwner?['phone'] ?? '+91 98200 11223';
                                Clipboard.setData(ClipboardData(text: p));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Owner number copied: $p'),
                                    backgroundColor: DriverTheme.statusOnline,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: DriverTheme.borderSubtle, height: 1),
                        const SizedBox(height: 10),

                        // Owner Alternative Mobile Number
                        Row(
                          children: [
                            const Icon(Icons.phone_forwarded, color: Color(0xFF2563EB), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'OWNER ALTERNATIVE NUMBER',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: DriverTheme.textMuted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _fleetOwner?['alternativePhone'] ?? '+91 98200 99887',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: DriverTheme.deepBlack,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18, color: DriverTheme.textMuted),
                              tooltip: 'Copy Alternative Phone',
                              onPressed: () {
                                final alt = _fleetOwner?['alternativePhone'] ?? '+91 98200 99887';
                                Clipboard.setData(ClipboardData(text: alt));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Owner alternative number copied: $alt'),
                                    backgroundColor: DriverTheme.statusOnline,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: DriverTheme.borderSubtle, height: 1),
                        const SizedBox(height: 10),

                        // Owner Office & Depot Address
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_city, color: DriverTheme.crimsonRed, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'OWNER OFFICE / DEPOT ADDRESS',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: DriverTheme.textMuted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _fleetOwner?['officeAddress'] ??
                                        'HAMHA Freight HQ, Plot 14, Bhiwandi Logistics Corridor, Thane, MH 421302',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: DriverTheme.deepBlack,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18, color: DriverTheme.textMuted),
                              tooltip: 'Copy Office Address',
                              onPressed: () {
                                final addr = _fleetOwner?['officeAddress'] ??
                                    'HAMHA Freight HQ, Plot 14, Bhiwandi Logistics Corridor, Thane, MH 421302';
                                Clipboard.setData(ClipboardData(text: addr));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Office address copied to clipboard!'),
                                    backgroundColor: DriverTheme.statusOnline,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),

            // 3. VEHICLE & FLEET ASSET SPECIFICATIONS
            _buildSectionHeader(
              'Assigned Vehicle & Telematics',
              Icons.local_shipping,
              trailing: InkWell(
                onTap: _showEditVehicleModal,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: const [
                      Icon(Icons.edit, size: 12, color: DriverTheme.crimsonRed),
                      SizedBox(width: 4),
                      Text(
                        'EDIT / ADD VEHICLE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: DriverTheme.crimsonRed,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: DriverTheme.crispWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DriverTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  _buildProfileRow('Asset Category', '$_vehicleType (Commercial Fleet)'),
                  const Divider(color: DriverTheme.borderSubtle, height: 20),
                  _buildProfileRow('Registration Plate', _plateNumber, isBold: true),
                  const Divider(color: DriverTheme.borderSubtle, height: 20),
                  _buildProfileRow('Vehicle Make & Model', _vehicleModel),
                  const Divider(color: DriverTheme.borderSubtle, height: 20),
                  _buildProfileRow('Payload & Volume Capacity', _payloadCapacity),
                  const Divider(color: DriverTheme.borderSubtle, height: 20),
                  _buildProfileRow('FASTag Electronic Toll', '$_fastagId (Active)', badge: '₹1,450'),
                  const Divider(color: DriverTheme.borderSubtle, height: 20),
                  _buildProfileRow('Pollution Clearance (PUC)', _pucValidity, badge: 'PASSED'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. STATUTORY COMPLIANCE & KYC
            _buildSectionHeader('Statutory Compliance & Licenses', Icons.verified_user),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: DriverTheme.crispWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DriverTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  _buildDocRow('Commercial Driver License (CDL)', 'MH-042019003841', 'VERIFIED'),
                  const Divider(color: DriverTheme.borderSubtle, height: 18),
                  _buildDocRow('Vehicle RC Smart Card', _plateNumber.replaceAll(' ', ''), 'VERIFIED'),
                  const Divider(color: DriverTheme.borderSubtle, height: 18),
                  _buildDocRow('Cargo & Transit Insurance', 'ICICI Lombard Policy #8841-B', 'ACTIVE'),
                  const Divider(color: DriverTheme.borderSubtle, height: 18),
                  _buildDocRow('Police Background Verification', 'Thane City Police Bureau', 'CLEARED'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. BANK & INSTANT PAYOUT SETTINGS
            _buildSectionHeader(
              'Bank & Instant Payout Settings',
              Icons.account_balance,
              trailing: InkWell(
                onTap: _showEditBankModal,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: const [
                      Icon(Icons.edit, size: 12, color: DriverTheme.crimsonRed),
                      SizedBox(width: 4),
                      Text(
                        'EDIT BANK & UPI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: DriverTheme.crimsonRed,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: DriverTheme.crispWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DriverTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  _buildProfileRow('Primary UPI ID', _upiId, badge: 'DEFAULT'),
                  const Divider(color: DriverTheme.borderSubtle, height: 20),
                  _buildProfileRow('Direct Salary Bank Account', '$_bankName $_accountNumber'),
                  const Divider(color: DriverTheme.borderSubtle, height: 20),
                  _buildProfileRow('Bank IFSC Code', _ifscCode),
                  const Divider(color: DriverTheme.borderSubtle, height: 20),
                  _buildSwitchRow(
                    'Daily Instant Auto-Settlement',
                    'Transfers cleared shift earnings automatically to UPI at 23:59',
                    _dailyPayouts,
                    (val) => setState(() => _dailyPayouts = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. OPERATING PREFERENCES
            _buildSectionHeader('Operating & Navigation Preferences', Icons.tune),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: DriverTheme.crispWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DriverTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  _buildSwitchRow(
                    'Turn-by-Turn Voice Navigation',
                    'Audible route instructions in English & Hindi',
                    _voiceGuidance,
                    (val) => setState(() => _voiceGuidance = val),
                  ),
                  const Divider(color: DriverTheme.borderSubtle, height: 16),
                  _buildSwitchRow(
                    'Loud Dispatch Sirens & Haptic',
                    'High-priority audio alerts for incoming 15s dispatches',
                    _soundAlerts,
                    (val) => setState(() => _soundAlerts = val),
                  ),
                  const Divider(color: DriverTheme.borderSubtle, height: 16),
                  _buildSwitchRow(
                    'Allow Expressways & FASTag Tolls',
                    'Faster transit routing with automated toll reimbursement',
                    _fastagExpressways,
                    (val) => setState(() => _fastagExpressways = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 6. EMERGENCY & DRIVER HELPLINE
            _buildSectionHeader('Safety & Emergency Helpline', Icons.health_and_safety),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: DriverTheme.crimsonTint,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DriverTheme.crimsonRed.withAlpha(80)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: DriverTheme.crimsonRed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.sos, color: DriverTheme.crispWhite, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '24x7 Carrier Pilot SOS Helpline',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: DriverTheme.deepBlack,
                              ),
                            ),
                            Text(
                              'Instant emergency dispatch and roadside assistance: 1800-HAMHA-PILOT',
                              style: TextStyle(fontSize: 11, color: DriverTheme.crimsonDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Connected to HAMHA Emergency Dispatch Desk.')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DriverTheme.crimsonDark,
                      side: const BorderSide(color: DriverTheme.crimsonRed),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.phone_in_talk, size: 16),
                    label: const Text('DIAL DRIVER HELPLINE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Sign out
            ElevatedButton.icon(
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: DriverTheme.deepBlack,
                foregroundColor: DriverTheme.crispWhite,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('END SHIFT & SIGN OUT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: DriverTheme.crimsonRed),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: DriverTheme.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildLifetimeStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: DriverTheme.deepBlack)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: DriverTheme.textMuted, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildProfileRow(String label, String value, {bool isBold = false, String? badge}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 4,
          child: Text(label, style: const TextStyle(fontSize: 13, color: DriverTheme.textMuted, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
                    color: DriverTheme.deepBlack,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: DriverTheme.warmCream,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: DriverTheme.borderSubtle),
                  ),
                  child: Text(badge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: DriverTheme.crimsonRed)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: DriverTheme.deepBlack)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: DriverTheme.textMuted)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: value,
          activeColor: DriverTheme.crimsonRed,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDocRow(String title, String docNumber, String status) {
    return InkWell(
      onTap: () => _showDocumentViewer(title, docNumber, status),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: DriverTheme.deepBlack)),
                  const SizedBox(height: 2),
                  Text(docNumber, style: const TextStyle(fontSize: 11, color: DriverTheme.textMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: DriverTheme.statusOnline.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DriverTheme.statusOnline),
              ),
              child: Text(
                status,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: DriverTheme.statusOnline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
