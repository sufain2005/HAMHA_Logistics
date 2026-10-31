import 'package:flutter/material.dart';
import '../../../core/theme/admin_theme.dart';
import '../../../core/models/owner_truck_requirement_model.dart';
import '../../../core/network/admin_api_client.dart';

class OwnerPostTruckRequirementModal extends StatefulWidget {
  final VoidCallback? onRequirementPosted;

  const OwnerPostTruckRequirementModal({super.key, this.onRequirementPosted});

  @override
  State<OwnerPostTruckRequirementModal> createState() => _OwnerPostTruckRequirementModalState();
}

class _OwnerPostTruckRequirementModalState extends State<OwnerPostTruckRequirementModal> {
  final _formKey = GlobalKey<FormState>();

  String _truckType = 'box_truck';
  final _titleController = TextEditingController(text: 'Require 10-Ton Box Truck for FMCG Cargo');
  final _cargoController = TextEditingController(text: 'Packaged FMCG & Dairy Goods');
  final _weightController = TextEditingController(text: '8.5');
  String _pickupState = 'Maharashtra';
  final _pickupCityController = TextEditingController(text: 'Bhiwandi');
  final _pickupAddressController = TextEditingController(text: 'Bhiwandi Logistics Park, Depot 4B, Thane');
  String _dropoffState = 'Maharashtra';
  final _dropoffCityController = TextEditingController(text: 'Pune');
  final _dropoffAddressController = TextEditingController(text: 'Chakan Industrial Phase II, Pune MIDC');
  final _fareController = TextEditingController(text: '18500');
  final _distanceController = TextEditingController(text: '158');
  final _phoneController = TextEditingController(text: '+91 98200 12345');
  final _whatsappController = TextEditingController(text: '+91 98200 12345');

  bool _isPosting = false;
  bool _isLoadingList = false;
  List<OwnerTruckRequirementModel> _activeList = [];
  int _activeTab = 0; // 0: Post Requirement, 1: Active 3-Day Broadcasts

  final List<String> _indianStates = [
    'Maharashtra',
    'Gujarat',
    'Karnataka',
    'Tamil Nadu',
    'Delhi NCR',
    'Telangana',
    'Uttar Pradesh',
    'West Bengal',
    'Rajasthan',
    'Madhya Pradesh',
  ];

  @override
  void initState() {
    super.initState();
    _loadRequirements();
  }

  Future<void> _loadRequirements() async {
    setState(() => _isLoadingList = true);
    final list = await AdminApiClient().fetchOwnerTruckRequirements();
    if (mounted) {
      setState(() {
        _activeList = list;
        _isLoadingList = false;
      });
    }
  }

  Future<void> _submitRequirement() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isPosting = true);

    final req = await AdminApiClient().postTruckRequirement(
      truckType: _truckType,
      title: _titleController.text.trim(),
      cargoType: _cargoController.text.trim(),
      weightTons: double.tryParse(_weightController.text.trim()) ?? 5.0,
      pickupState: _pickupState,
      pickupCity: _pickupCityController.text.trim(),
      pickupAddress: _pickupAddressController.text.trim(),
      dropoffState: _dropoffState,
      dropoffCity: _dropoffCityController.text.trim(),
      dropoffAddress: _dropoffAddressController.text.trim(),
      offeredFare: double.tryParse(_fareController.text.trim()) ?? 15000.0,
      distanceKm: double.tryParse(_distanceController.text.trim()) ?? 150.0,
      contactPhone: _phoneController.text.trim(),
      contactWhatsapp: _whatsappController.text.trim(),
    );

    if (mounted) {
      setState(() => _isPosting = false);
      if (req != null) {
        widget.onRequirementPosted?.call();
        _loadRequirements();
        setState(() => _activeTab = 1);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Truck requirement broadcasted successfully to drivers for 3 days!'),
            backgroundColor: AdminTheme.statusOnline,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to broadcast requirement to database. Please check connection.'),
            backgroundColor: AdminTheme.crimsonRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminTheme.crispWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AdminTheme.borderSubtle),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 750),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AdminTheme.borderSubtle)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AdminTheme.crimsonRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.travel_explore, color: AdminTheme.crispWhite, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Owner Load Board: Search for Truck',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AdminTheme.deepBlack),
                        ),
                        Text(
                          'Broadcast truck requirements to regional drivers for 3 days (72 hours).',
                          style: TextStyle(fontSize: 12, color: AdminTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AdminTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tab Navigation Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              color: AdminTheme.warmCream,
              child: Row(
                children: [
                  _buildTabPill(0, '+ Post New Requirement (3-Day Broadcast)'),
                  const SizedBox(width: 8),
                  _buildTabPill(1, 'Active Broadcasts (${_activeList.length})'),
                ],
              ),
            ),

            // Tab Body
            Expanded(
              child: _activeTab == 0 ? _buildPostFormView() : _buildActiveListView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill(int index, String title) {
    final isSel = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? AdminTheme.deepBlack : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isSel ? AdminTheme.crispWhite : AdminTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildPostFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 3-Day Notice Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AdminTheme.warmCream,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminTheme.crimsonRed.withAlpha(60)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_top, color: AdminTheme.crimsonRed, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '3-DAY ACTIVE SEARCH WINDOW (72 HOURS)',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AdminTheme.crimsonRed, letterSpacing: 0.6),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Your posting will be actively broadcasted to all drivers in the selected state. Drivers can view live specs and call or WhatsApp you directly.',
                          style: TextStyle(fontSize: 11.5, color: AdminTheme.textDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Truck Type & Tonnage
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('REQUIRED TRUCK TYPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminTheme.textMuted)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _truckType,
                        dropdownColor: AdminTheme.crispWhite,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AdminTheme.warmCream,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'box_truck', child: Text('10-Ton Box Truck')),
                          DropdownMenuItem(value: 'mini_truck', child: Text('Tata Ace / Mini Truck')),
                          DropdownMenuItem(value: 'heavy_freight', child: Text('16-Tire Multi-Axle Heavy')),
                          DropdownMenuItem(value: 'trailer', child: Text('Articulated Container Trailer')),
                          DropdownMenuItem(value: 'van', child: Text('Pharma Insulated Van')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _truckType = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('LOAD WEIGHT (TONS)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminTheme.textMuted)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AdminTheme.warmCream,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title & Cargo
            const Text('REQUIREMENT TITLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminTheme.textMuted)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                filled: true,
                fillColor: AdminTheme.warmCream,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CARGO CLASSIFICATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminTheme.textMuted)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _cargoController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AdminTheme.warmCream,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('OFFERED FARE (INR ₹)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminTheme.textMuted)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _fareController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.crimsonRed),
                        decoration: InputDecoration(
                          prefixText: '₹ ',
                          filled: true,
                          fillColor: AdminTheme.warmCream,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pickup & Dropoff State/Address
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PICKUP STATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminTheme.textMuted)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _pickupState,
                        dropdownColor: AdminTheme.crispWhite,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AdminTheme.warmCream,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _pickupState = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PICKUP CITY & DEPOT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminTheme.textMuted)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _pickupAddressController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AdminTheme.warmCream,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DROP-OFF STATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminTheme.textMuted)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _dropoffState,
                        dropdownColor: AdminTheme.crispWhite,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AdminTheme.warmCream,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _dropoffState = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DROP-OFF CITY & FACILITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminTheme.textMuted)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _dropoffAddressController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AdminTheme.warmCream,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Contact Phone & WhatsApp
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('OWNER PHONE FOR DRIVERS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminTheme.textMuted)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AdminTheme.warmCream,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('WHATSAPP NUMBER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminTheme.textMuted)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _whatsappController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AdminTheme.warmCream,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: AdminTheme.textMuted, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isPosting ? null : _submitRequirement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.crimsonRed,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isPosting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, size: 16),
                  label: const Text('BROADCAST 3-DAY REQUIREMENT', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveListView() {
    if (_isLoadingList) {
      return const Center(child: CircularProgressIndicator(color: AdminTheme.crimsonRed));
    }
    if (_activeList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 48, color: AdminTheme.textMuted),
            const SizedBox(height: 12),
            const Text('No active 3-day load broadcasts found.', style: TextStyle(fontWeight: FontWeight.w800, color: AdminTheme.textDark)),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => setState(() => _activeTab = 0),
              child: const Text('+ Post Your First Requirement', style: TextStyle(color: AdminTheme.crimsonRed, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _activeList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final req = _activeList[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AdminTheme.warmCream,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AdminTheme.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: req.urgencyColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.timer, color: req.urgencyColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            req.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AdminTheme.deepBlack),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: req.urgencyColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            req.remainingTimeFormatted,
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: req.urgencyColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${req.truckTypeDisplayName} • ${req.pickupCity} (${req.pickupState}) ➔ ${req.dropoffCity} (${req.dropoffState}) • ₹${req.offeredFare.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 11, color: AdminTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: AdminTheme.deepBlack),
                    tooltip: 'Edit Requirement Details',
                    onPressed: () => _showEditRequirementDialog(req),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: AdminTheme.crimsonRed),
                    tooltip: 'Remove / Cancel Posting',
                    onPressed: () => _confirmCancelRequirement(req),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditRequirementDialog(OwnerTruckRequirementModel req) {
    final titleCtrl = TextEditingController(text: req.title);
    final fareCtrl = TextEditingController(text: req.offeredFare.toStringAsFixed(0));
    final weightCtrl = TextEditingController(text: req.weightTons.toString());
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AdminTheme.crispWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit_note, color: AdminTheme.crimsonRed),
              SizedBox(width: 8),
              Text('Update Load Broadcast', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Corridor Route: ${req.pickupCity} (${req.pickupState}) ➔ ${req.dropoffCity} (${req.dropoffState})',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AdminTheme.textMuted),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Consignment Title'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: fareCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Offered Fare (₹ INR)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: weightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Weight (Tons)'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: AdminTheme.textMuted, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDlgState(() => isSaving = true);
                      final updated = await AdminApiClient().updateTruckRequirement(
                        id: req.id,
                        title: titleCtrl.text.trim(),
                        offeredFare: double.tryParse(fareCtrl.text.trim()) ?? req.offeredFare,
                        weightTons: double.tryParse(weightCtrl.text.trim()) ?? req.weightTons,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        _loadRequirements();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(updated != null
                                ? 'Requirement updated in database successfully!'
                                : 'Failed to update requirement.'),
                            backgroundColor: updated != null ? AdminTheme.statusOnline : AdminTheme.crimsonRed,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.crimsonRed,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancelRequirement(OwnerTruckRequirementModel req) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminTheme.crispWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AdminTheme.crimsonRed),
            SizedBox(width: 8),
            Text('Remove Load Posting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel and remove "${req.title}"?\nDrivers searching for work in ${req.pickupState} will immediately no longer see this load broadcast.',
          style: const TextStyle(fontSize: 13, color: AdminTheme.deepBlack),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('KEEP POSTING', style: TextStyle(color: AdminTheme.textMuted, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await AdminApiClient().cancelTruckRequirement(req.id);
              if (mounted) {
                _loadRequirements();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Load posting cancelled and removed from active board.'
                        : 'Failed to cancel posting.'),
                    backgroundColor: success ? AdminTheme.deepBlack : AdminTheme.crimsonRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.crimsonRed,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('CONFIRM REMOVE', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

